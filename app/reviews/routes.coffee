exports.route = (app) ->
  pub = app.apps.reviews.controller.public
  admin = app.apps.reviews.controller.admin
  service = app.apps.reviews.controller.service
  shared = app.apps.shared.controller.public

  app.post '/reviews/github', service.create

  app.get "/admin/reviews/index", require_admin, admin.index
  actions =
    "": "index"
    all: "index"
    index: "index"
    active: "active"
    error: "error"
    completed: "completed"
    pending: "pending"

  Object.keys(actions).each (key) ->
    app.get ["/admin/reviews", key].remove('').join('/'), require_admin, admin[actions[key]]

  app.get "/admin/reviews/:id", require_admin, admin.show
  app.post '/admin/reviews/:id/pull', require_admin, admin.pull
  app.post '/admin/reviews/:id/analyze', require_admin, admin.analyze
  app.post '/admin/reviews/:id/push', require_admin, admin.push
  app.delete '/admin/reviews/:id', require_admin, admin.del
  app.get '/admin/reviews/:id/raw', require_admin, admin.raw
  app.get '/admin/reviews/:id/comments', require_admin, admin.comments

