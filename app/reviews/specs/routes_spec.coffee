require("../../shared/specs/helpers")

describe "Reviews Routes", ->
  describe "for public", ->
    shouldHaveRoutes({
      'post /reviews/github': 'reviews.service.create'
    }, null)

