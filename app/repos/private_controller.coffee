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

