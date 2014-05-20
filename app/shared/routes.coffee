exports.route = (app) ->
  usersAdmin = app.apps.users.controller.admin
  pub = app.apps.shared.controller.public

  app.get '/', pub.index

