exports.route = (app) ->
  #admin = app.apps.repos.controller.admin
  priv = app.apps.repos.controller.private
  #pub = app.apps.repos.controller.public
  shared = app.apps.shared.controller.public

  app.get '/private', require_user, priv.index
  app.get '/private/repos', require_user, priv.index
  app.get '/private/repos/index', require_user, priv.index

