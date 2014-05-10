require("../../shared/specs/helpers")

describe "Users Routes", ->
  describe 'for private', ->
    shouldHaveRoutes({
      'get /private': 'repos.private.index'
      'get /private/repos': 'repos.private.index'
      'get /private/repos/index': 'repos.private.index'
    }, { username: 'dmskr' })

  describe "for private", ->
    shouldNotHaveRoutes([])

