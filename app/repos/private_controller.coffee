async = require "async"

module.exports = (Bot, done) ->
  exports = {}
  exports.index = (req, res, next) ->
    github = new Bot.GitHub({ version: '3.0.0' })
    github.authenticate({
      type: 'oauth',
      token: req.user.github.accessToken
    })
    query = {
      repos: (callback) ->
        github.repos.getAll { sort: 'updated', per_page: 100, type: 'all' }, callback
      accounts: (callback) -> github.orgs.getFromUser { user: req.user.github.username, per_page: 100 }, callback
      nagging: (callback) -> Bot.db.repos.find(user: req.user._id, active: true).toArray callback
    }
    if req.query.organization
      query.repos = (callback) -> github.repos.getFromOrg { org: req.query.organization.toLowerCase(), sort: 'updated', per_page: 100, type: 'all' }, callback

    async.parallel query, (err, result) ->
      return next(err) if err
      result.accounts.each (account) -> account.type = 'organization'
      (result.accounts || []).unshift Object.merge(req.user.github, { login: req.user.github.username, type: 'user' })
      result.selectedAccount = req.user.github
      if req.query.organization
        result.selectedAccount = result.accounts.find (account) -> account.login.toLowerCase() == req.query.organization.toLowerCase()

      result.repos.each (repo) ->
        nagging = result.nagging.find (n) ->
          n.github.name == repo.name && n.github.owner.login == repo.owner.login
        if nagging
          repo.nagging = true

      res.render "#{Bot.root}/app/repos/private/index.jade", result

  exports.ignored = exports.index

  exports.watched = exports.index

  exports.create = (req, res, next) ->
    github = new Bot.GitHub({ version: '3.0.0' })
    github.authenticate({
      type: 'oauth'
      token: req.user.github.accessToken
    })

    github.repos.createHook {
      user: req.body.repo.owner.login
      repo: req.body.repo.name
      name: 'web'
      config:
        'url': "http://#{Bot.express.settings.host}/reviews/github"
        'content-type': 'application/json'
      events: ['pull_request']
      active: true
    }, (err) ->
      if err
        errcode = {
          "resource": "Hook",
          "code": "custom",
          "message": "Hook already exists on this repository"
        }
        if (err.errors || []).any((error) -> !Object.equal(error, errcode))
          return next(err)

      Bot.db.repos.find({
        user: req.user._id
        'github.name': req.body.repo.name
        'github.owner.login': req.body.repo.owner.login
      }).toArray (err, repos) ->
        return next(err) if err
        repo = repos.first()
        repo ||=
          user: req.user._id
          github: Object.select(req.body.repo, ['name', 'owner'])
        repo.active = true

        Bot.db.repos.save repo, (err, result) ->
          return next(err) if err
          req.flash 'success', 'Nagging your repo. Watch Out!'
          res.redirect '/private/repos/'

  exports.delete = (req, res, next) ->
    github = new Bot.GitHub({ version: '3.0.0' })
    github.authenticate({
      type: 'oauth'
      token: req.user.github.accessToken
    })

    github.repos.getHooks {
      user: req.params.owner
      repo: req.params.name
      per_page: 100
    }, (err, hooks) ->
      return next(err) if (err)
      Bot.db.repos.find('github.name': req.params.name, 'github.owner.login': req.params.owner).toArray (err, repos) ->
        return next(err) if err
        repo = repos.first()
        async.each hooks, (hook, callback) ->
          unless hook.config && hook.config.url && hook.config.url.match(new RegExp("^https?:\/\/" + req.host))
            return callback()
          github.repos.deleteHook {
            user: req.params.owner
            repo: req.params.name
            id: hook.id
          }, callback
        , (err) ->
          return next(err) if err
          repo.active = false
          Bot.db.repos.save repo, (err) ->
            return next(err) if err
            req.flash 'success', 'Ok. Stopped Nag You with the repo.'
            res.redirect '/private/repos'
  done(null, exports)

