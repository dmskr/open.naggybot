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
      'post /private/repos': 'repos.private.create'
      'delete /private/repos/:owner/:name': 'repos.private.delete'
    }, { username: 'dmskr' })

  describe "for private", ->
    shouldNotHaveRoutes([], { username: 'monkey' }, 'repos')

  describe "for public", ->
    shouldNotHaveRoutes [
      'get /private'
      'get /private/repos'
      'get /private/repos/index'
      'get /private/repos/all'
      'get /private/repos/watched'
      'get /private/repos/ignored'
      'post /private/repos/'
      'delete /private/repos/:owner/:name'
    ], null, 'repos'

