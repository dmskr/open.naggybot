exports.route = (app) ->
  priv = app.apps.repos.controller.private
  shared = app.apps.shared.controller.public

  app.get '/private', require_user, priv.index
  app.get '/private/repos', require_user, priv.index
  app.get '/private/repos/index', require_user, priv.index
  app.get '/private/repos/all', require_user, priv.index
  app.get '/private/repos/watched', require_user, priv.watched
  app.get '/private/repos/ignored', require_user, priv.ignored
  app.post '/private/repos', require_user, priv.create
  app.delete '/private/repos/:owner/:name', require_user, priv.delete

