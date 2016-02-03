require("../../shared/specs/helpers") ->

  describe "Users Routes", ->
    describe 'for admin', ->
      shouldHaveRoutes({
        'get /admin': 'users.admin.index',
        'get /admin/users': 'users.admin.index',
        'get /admin/users/all': 'users.admin.index',
        'get /admin/users/blocked': 'users.admin.blocked',
        'get /admin/users/active': 'users.admin.active',
        'get /admin/users/search': 'users.admin.search',
        'get /admin/users/autocomplete': 'users.admin.autocomplete',
        'get /admin/users/user_id': 'users.admin.show',
        'put /admin/users/user_id': 'users.admin.update',
        'post /admin/users/user_id': 'users.admin.update',
      }, { username: 'dmskr', admin: true })

    describe "for private", ->
      shouldNotHaveRoutes([
        "get /admin",
        "get /admin/users",
        "get /admin/users/all",
        "get /admin/users/blocked",
        "get /admin/users/active",
        "get /admin/users/search",
        "get /admin/users/autocomplete",
        "get /admin/users/new",
        "get /admin/users/user_id",
        "put /admin/users/user_id",
        "post /admin/users/user_id"
      ], { username: 'dmskr' }, 'users')

      shouldHaveRoutes({
        'get /private/users/current': 'users.private.current'
        'post /private/users/current': 'users.private.update'
      }, { username: 'dmskr' })

    describe "for public", ->
      shouldNotHaveRoutes([
        "get /admin",
        "get /admin/users",
        "get /admin/users/all",
        "get /admin/users/blocked",
        "get /admin/users/active",
        "get /admin/users/search",
        "get /admin/users/autocomplete",
        "get /admin/users/new",
        "get /admin/users/user_id",
        "put /admin/users/user_id",
        "post /admin/users/user_id"
      ], null, 'users')

      shouldHaveRoutes({
        'get /login': 'users.sessions.new',
        'post /login': 'users.sessions.create',
        'post /logout': 'users.sessions.delete',
        'get /signup': 'users.public.new',
        'post /signup': 'users.public.create'
      }, null)

