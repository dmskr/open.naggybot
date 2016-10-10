exports.route = Bot => {
  const usersAdmin = Bot.apps.users.controller.admin;
  const controller = Bot.apps.shared.controller;

  const app = Bot.express;
  app.get('/', controller.public.index);
}

