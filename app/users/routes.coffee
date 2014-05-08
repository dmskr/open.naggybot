exports.route = (app) ->
  pub = app.apps.users.controller.public
  priv = app.apps.users.controller.private
  sessions = app.apps.users.controller.sessions
  shared = app.apps.shared.controller.public

  app.get '/login', sessions.new
  app.post '/login', sessions.create
  app.post '/logout', sessions.del
  app.get '/signup', pub.new
  app.post '/signup', pub.create

