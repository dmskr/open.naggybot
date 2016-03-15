exports.route = (Bot) ->
  pub = Bot.apps.reviews.controller.public
  admin = Bot.apps.reviews.controller.admin
  service = Bot.apps.reviews.controller.service
  shared = Bot.apps.shared.controller.public

  app = Bot.express
  app.post '/reviews/github', service.create

  app.get "/admin/reviews/index", Bot.require_admin, admin.index
  actions =
    "": "index"
    all: "index"
    index: "index"
    active: "active"
    error: "error"
    completed: "completed"
    pending: "pending"

  Object.keys(actions).each (key) ->
    app.get ["/admin/reviews", key].remove('').join('/'), Bot.require_admin, admin[actions[key]]

  app.get "/admin/reviews/:id", Bot.require_admin, admin.show
  app.post '/admin/reviews/:id/pull', Bot.require_admin, admin.pull
  app.post '/admin/reviews/:id/analyze', Bot.require_admin, admin.analyze
  app.post '/admin/reviews/:id/push', Bot.require_admin, admin.push
  app.delete '/admin/reviews/:id', Bot.require_admin, admin.delete
  app.get '/admin/reviews/:id/raw', Bot.require_admin, admin.raw
  app.get '/admin/reviews/:id/comments', Bot.require_admin, admin.comments

