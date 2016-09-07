exports.route = (Bot) ->
  controller = Bot.apps.repos.controller

  app = Bot.express
  app.get '/private', Bot.require_user, controller.private.index
  app.get '/private/repos', Bot.require_user, controller.private.index
  app.get '/private/repos/index', Bot.require_user, controller.private.index
  app.get '/private/repos/all', Bot.require_user, controller.private.index
  app.get '/private/repos/watched', Bot.require_user, controller.private.watched
  app.get '/private/repos/ignored', Bot.require_user, controller.private.ignored
  app.post '/private/repos', Bot.require_user, controller.private.create
  app.delete '/private/repos/:owner/:name', Bot.require_user, controller.private.delete

