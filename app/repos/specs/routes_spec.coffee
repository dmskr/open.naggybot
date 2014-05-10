require("../../shared/specs/helpers")

describe "Users Routes", ->
  describe 'for private', ->
    shouldHaveRoutes({
      'get /private': 'repos.private.index'
      'get /private/repos': 'repos.private.index'
      'get /private/repos/index': 'repos.private.index'
      'get /private/repos/all': 'repos.private.index'
      'get /private/repos/watched': 'repos.private.watched'
      'get /private/repos/ignored': 'repos.private.ignored'
    }, { username: 'dmskr' })

  describe "for private", ->
    shouldNotHaveRoutes([])

