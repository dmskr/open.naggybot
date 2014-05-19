exports.index = (req, res, next) ->
  github = new global.GitHub({ version: '3.0.0' })
  github.authenticate({
    type: 'oauth',
    token: req.user.provider.github.accessToken
  })
  query = {
    repos: (callback) ->
      github.repos.getAll { sort: 'updated', per_page: 100, type: 'all' }, callback
    accounts: (callback) -> github.orgs.getFromUser { user: req.user.provider.github.username, per_page: 100 }, callback
  }
  if req.query.organization
    query.repos = (callback) -> github.repos.getFromOrg { org: req.query.organization.toLowerCase(), sort: 'updated', per_page: 100, type: 'all' }, callback

  async.parallel query, (err, result) ->
    return next(err) if err
    result.accounts.each (account) -> account.type = 'organization'
    (result.accounts || []).unshift Object.merge(req.user.provider.github, { login: req.user.provider.github.username, type: 'user' })
    result.selectedAccount = req.user.provider.github
    if req.query.organization
      result.selectedAccount = result.accounts.find (account) -> account.login.toLowerCase() == req.query.organization.toLowerCase()

    res.render "#{Bot.root}/app/repos/private/index.jade", result

exports.ignored = exports.index

exports.watched = exports.index

exports.create = (req, res, next) ->
  github = new GitHub({ version: '3.0.0' })
  github.authenticate({
    type: 'oauth'
    token: req.user.provider.github.accessToken
  })

  github.repos.createHook {
    user: req.body.repo.owner.login
    repo: req.body.repo.name
    name: 'web'
    config:
      'url': "http://#{req.host}/pulls/github/callback"
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

exports.del = (req, res, next) ->
  github = new GitHub({ version: '3.0.0' })
  github.authenticate({
    type: 'oauth'
    token: req.user.provider.github.accessToken
  })

  Bot.db.repos.findById req.params.id, (err, repo) ->
    return next(err) if err
    Bot.db.users.findById repo.user, (err, user) ->
      return next(err) if err
      github.repos.getHooks {
        user: user.provider.github.username
        repo: repo.full_name
        per_page: 100
      }, (err, result) ->
        return next(err) if (err)
        async.each result, (hook, callback) ->
          unless hook.config && hook.config.url && hook.config.url.match(new RegExp("^https?:\/\/" + req.hostname))
            return callback()
          github.repos.deleteHook {
            user: user.provider.github.username
            repo: repo.full_name
            id: hook.id
          }, callback
        , (err) ->
          return next(err) if err
          repo.active = false
          Bot.db.repos.save repo, (err) ->
            return next(err) if err
            res.json '200', repo: repo

