require("../../shared/specs/helpers")

describe "Repos Private Controller", ->
  originalGitHub = null
  beforeEach (done) ->
    originalGitHub = global.GitHub
    global.GitHub = ->
    global.GitHub.prototype.authenticate = ->
    global.GitHub.prototype.repos = {}
    global.GitHub.prototype.repos.getAll = (params, callback) ->
      fs.readFile "#{Bot.root}/app/repos/specs/allRepos.json", (err, content) ->
        return done(err) if err
        callback(null, JSON.parse(content))

    req.user =
      provider:
        github:
          accessToken: '321'
    done()

  afterEach (done) ->
    global.GitHub = originalGitHub
    done()

  describe "index", ->
    it "should authentificate github request with user's accessToken", (done) ->
      global.GitHub.prototype.authenticate = (args) ->
        args.type.should.eql 'oauth'
        args.token.should.eql '321'
        done()
        return null
      Bot.apps.repos.controller.private.index req, res, next

    it "should list all repos belonged to the user sorted by 'updated' date", (done) ->
      global.GitHub.prototype.repos.getAll = (args) ->
        args.sort.should.eql 'updated'
        done()
      Bot.apps.repos.controller.private.index req, res, next

    it "should render index.jade template", (done) ->
      res.render = (template, params) ->
        template.should.eql "#{Bot.root}/app/repos/private/index.jade"
        should.exist params.repos
        params.repos.length.should.eql 8
        done()
      Bot.apps.repos.controller.private.index req, res, next

