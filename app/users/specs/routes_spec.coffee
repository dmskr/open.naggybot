require("../../shared/specs/helpers")

describe "Users Routes", ->
  describe "for public", ->
    shouldHaveRoutes({
      'get /login': 'users.sessions.new',
      'post /login': 'users.sessions.create',
      'post /logout': 'users.sessions.del',
      'get /signup': 'users.public.new',
      'post /signup': 'users.public.create'
    }, null)

