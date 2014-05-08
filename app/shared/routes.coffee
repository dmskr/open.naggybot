exports.route = (app) ->
  pub = app.apps.shared.controller.public
  app.get('/', pub.index)

