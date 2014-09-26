exports.route = (app) ->
  admin = app.apps.users.controller.admin
  priv = app.apps.users.controller.private
  pub = app.apps.users.controller.public
  sessions = app.apps.users.controller.sessions
  shared = app.apps.shared.controller.public

  app.get '/admin', require_admin, admin.index
  app.get '/admin/users', require_admin, admin.index
  app.get '/admin/users/all', require_admin, admin.index
  app.get '/admin/users/blocked', require_admin, admin.blocked
  app.get '/admin/users/active', require_admin, admin.active
  app.get '/admin/users/search', require_admin, admin.search
  app.get '/admin/users/autocomplete', require_admin, admin.autocomplete
  app.get '/admin/users/:id', require_admin, admin.show
  app.put '/admin/users/:id', require_admin, admin.update
  app.post '/admin/users/:id', require_admin, admin.update

  app.get '/private/users/current', require_user, priv.current
  app.post '/private/users/current', require_user, priv.update

  app.get '/login', sessions.new
  app.post '/login', sessions.create
  app.post '/logout', sessions.delete
  app.get '/signup', pub.new
  app.post '/signup', pub.create

  app.get '/auth/github', passport.authenticate('github'), ->

  app.get '/auth/github/callback', (req, res, next) ->
    passport.authenticate('github', (err, user, info) ->
      return next(err) if err
      return res.redirect('/login') unless user
      req.logIn user, (err) ->
        return next(err) if err
        res.redirect '/private'
    )(req, res, next)

