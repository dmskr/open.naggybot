exports.route = (app) ->
  pub = app.apps.reviews.controller.public
  service = app.apps.reviews.controller.service
  shared = app.apps.shared.controller.public

  app.post '/reviews/github', service.create

