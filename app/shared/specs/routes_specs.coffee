require("../../shared/specs/helpers")

describe "Shared Routes", ->
  describe 'for public', ->
    shouldHaveRoutes({
      'get /': 'shared.public.index'
    }, null)

