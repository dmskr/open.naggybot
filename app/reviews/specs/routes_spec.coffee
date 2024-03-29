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
      'post /admin/reviews/:id/pull': 'reviews.admin.pull'
      'post /admin/reviews/:id/analyze': 'reviews.admin.analyze'
      'post /admin/reviews/:id/push': 'reviews.admin.push'
      'delete /admin/reviews/:id': 'reviews.admin.delete'
      'get /admin/reviews/:id/raw': 'reviews.admin.raw'
      'get /admin/reviews/:id/comments': 'reviews.admin.comments'
    }, { username: 'monkey', admin: true }, 'reviews')

  describe "for private", ->
    shouldNotHaveRoutes([
      "get /admin/reviews"
      "get /admin/reviews/index"
      "get /admin/reviews/all"
      "get /admin/reviews/active"
      "get /admin/reviews/error"
      "get /admin/reviews/completed"
      "get /admin/reviews/pending"
      "post /admin/reviews/:id/pull"
      "post /admin/reviews/:id/analyze"
      "post /admin/reviews/:id/push"
      "delete /admin/reviews/:id"
      "get /admin/reviews/:id/raw"
      "get /admin/reviews/:id/comments"
    ], { username: 'monkey' }, 'reviews')

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
      "post /admin/reviews/:id/pull"
      "post /admin/reviews/:id/analyze"
      "post /admin/reviews/:id/push"
      "delete /admin/reviews/:id"
      "get /admin/reviews/:id/raw"
      "get /admin/reviews/:id/comments"
    ], null, 'reviews')
