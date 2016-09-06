exports.route = (Bot) ->
  usersAdmin = Bot.apps.users.controller.admin
  controller = Bot.apps.shared.controller

  app = Bot.express
  app.get '/', controller.public.index

