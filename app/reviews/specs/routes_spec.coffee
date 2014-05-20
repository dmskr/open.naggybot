require("../../shared/specs/helpers")

describe "Reviews Routes", ->
  describe 'for admin', ->
    shouldHaveRoutes({
      'get /admin/reviews': 'reviews.admin.index'
      'get /admin/reviews/index': 'reviews.admin.index'
      'get /admin/reviews/all': 'reviews.admin.index'
      'get /admin/reviews/active': 'reviews.admin.active'
      'get /admin/reviews/error': 'reviews.admin.error'
      'get /admin/reviews/completed': 'reviews.admin.completed'
      'get /admin/reviews/pending': 'reviews.admin.pending'
    }, { username: 'monkey', admin: true }, 'reviews')

  describe "for public", ->
    shouldHaveRoutes({
      'post /reviews/github': 'reviews.service.create'
    }, null)

    shouldNotHaveRoutes([
      "get /admin/reviews"
      "get /admin/reviews/index"
      "get /admin/reviews/all"
      "get /admin/reviews/active"
      "get /admin/reviews/error"
      "get /admin/reviews/completed"
      "get /admin/reviews/pending"
    ], null, 'users')
