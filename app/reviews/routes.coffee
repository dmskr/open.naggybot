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
