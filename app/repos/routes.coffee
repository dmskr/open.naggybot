exports.route = (Bot) ->
  priv = Bot.apps.repos.controller.private
  shared = Bot.apps.shared.controller.public

  app = Bot.express
  app.get '/private', Bot.require_user, priv.index
  app.get '/private/repos', Bot.require_user, priv.index
  app.get '/private/repos/index', Bot.require_user, priv.index
  app.get '/private/repos/all', Bot.require_user, priv.index
  app.get '/private/repos/watched', Bot.require_user, priv.watched
  app.get '/private/repos/ignored', Bot.require_user, priv.ignored
  app.post '/private/repos', Bot.require_user, priv.create
  app.delete '/private/repos/:owner/:name', Bot.require_user, priv.delete

