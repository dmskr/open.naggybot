exports.index = (req, res, next) ->
  github = new global.GitHub({ version: '3.0.0' })
  github.authenticate({
    type: 'oauth',
    token: req.user.provider.github.accessToken
  })
  github.repos.getAll { sort: 'updated' }, (err, result) ->
    return next(err) if err
    res.render "#{Bot.root}/app/repos/private/index.jade", { data: result, tab: 'all' }

exports.ignored = exports.index

exports.watched = exports.index

exports.create = (req, res, next) ->
  github = new GitHub({ version: '3.0.0' })
  github.authenticate({
    type: 'oauth'
    token: req.user.provider.github.accessToken
  })

  github.repos.createHook {
    user: req.user.provider.github.username
    repo: req.body.repo.name
    name: 'web'
    config:
      'url': "http://#{req.host}/pulls/github/callback"
      'content-type': 'application/json'
    events: ['pull_request']
    active: true
  }, (err) ->
    return next(err) if err
    repo =
      active: true
      user: req.user._id
      provider:
        github: Object.select(req.body.repo, ['id', 'name', 'full_name'])

    Bot.db.repos.save repo, (err, result) ->
      return next(err) if err
      req.flash 'success', 'Watching your repo, Dude.'
      res.redirect '/private/repos/' + result._id

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

