exports.route = function(Bot) {
  var actions, app, controller;
  controller = Bot.apps.reviews.controller;

  app = Bot.express;
  app.post('/reviews/github', controller.service.create);

  app.get("/admin/reviews/index", Bot.require_admin, controller.admin.index);
  actions = {
    "": "index",
    all: "index",
    index: "index",
    active: "active",
    error: "error",
    completed: "completed",
    pending: "pending"
  };

  Object.keys(actions).each (function(key) {
    return app.get(["/admin/reviews", key].remove('').join('/'), Bot.require_admin, controller.admin[actions[key]]);
  });

  app.get ("/admin/reviews/:id", Bot.require_admin, controller.admin.show);
  app.post ('/admin/reviews/:id/pull', Bot.require_admin, controller.admin.pull);
  app.post ('/admin/reviews/:id/analyze', Bot.require_admin, controller.admin.analyze);
  app.post ('/admin/reviews/:id/push', Bot.require_admin, controller.admin.push);
  app["delete"]('/admin/reviews/:id', Bot.require_admin, controller.admin["delete"]);
  app.get ('/admin/reviews/:id/raw', Bot.require_admin, controller.admin.raw);
  return app.get ('/admin/reviews/:id/comments', Bot.require_admin, controller.admin.comments);
};
