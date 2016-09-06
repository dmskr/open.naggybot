passport = require("passport")
exports.route = (Bot) ->
  controller = Bot.apps.users.controller

  app = Bot.express
  app.get '/admin', Bot.require_admin, controller.admin.index
  app.get '/admin/users', Bot.require_admin, controller.admin.index
  app.get '/admin/users/all', Bot.require_admin, controller.admin.index
  app.get '/admin/users/blocked', Bot.require_admin, controller.admin.blocked
  app.get '/admin/users/active', Bot.require_admin, controller.admin.active
  app.get '/admin/users/search', Bot.require_admin, controller.admin.search
  app.get '/admin/users/autocomplete', Bot.require_admin, controller.admin.autocomplete
  app.get '/admin/users/:id', Bot.require_admin, controller.admin.show
  app.put '/admin/users/:id', Bot.require_admin, controller.admin.update
  app.post '/admin/users/:id', Bot.require_admin, controller.admin.update

  app.get '/private/users/current', Bot.require_user, controller.private.current
  app.post '/private/users/current', Bot.require_user, controller.private.update

  app.get '/login', controller.sessions.new
  app.post '/login', controller.sessions.create
  app.post '/logout', controller.sessions.delete
  app.get '/signup', controller.public.new
  app.post '/signup', controller.public.create

  app.get '/auth/github', passport.authenticate('github'), ->

  app.get '/auth/github/callback', (req, res, next) ->
    passport.authenticate('github', (err, user, info) ->
      return next(err) if err
      return res.redirect('/login') unless user
      req.logIn user, (err) ->
        return next(err) if err
        res.redirect '/private'
    )(req, res, next)

