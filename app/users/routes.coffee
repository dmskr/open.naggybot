passport = require("passport")
exports.route = (Bot) ->
  admin = Bot.apps.users.controller.admin
  priv = Bot.apps.users.controller.private
  pub = Bot.apps.users.controller.public
  sessions = Bot.apps.users.controller.sessions
  shared = Bot.apps.shared.controller.public

  app = Bot.express
  app.get '/admin', Bot.require_admin, admin.index
  app.get '/admin/users', Bot.require_admin, admin.index
  app.get '/admin/users/all', Bot.require_admin, admin.index
  app.get '/admin/users/blocked', Bot.require_admin, admin.blocked
  app.get '/admin/users/active', Bot.require_admin, admin.active
  app.get '/admin/users/search', Bot.require_admin, admin.search
  app.get '/admin/users/autocomplete', Bot.require_admin, admin.autocomplete
  app.get '/admin/users/:id', Bot.require_admin, admin.show
  app.put '/admin/users/:id', Bot.require_admin, admin.update
  app.post '/admin/users/:id', Bot.require_admin, admin.update

  app.get '/private/users/current', Bot.require_user, priv.current
  app.post '/private/users/current', Bot.require_user, priv.update

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

