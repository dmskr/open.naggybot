exports.route = (app) ->
  pub = app.apps.reviews.controller.public
  shared = app.apps.shared.controller.public

  app.post '/reviews/github', pub.create

