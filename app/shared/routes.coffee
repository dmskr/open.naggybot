exports.route = (Bot) ->
  usersAdmin = Bot.apps.users.controller.admin
  pub = Bot.apps.shared.controller.public

  app = Bot.express
  app.get '/', pub.index

