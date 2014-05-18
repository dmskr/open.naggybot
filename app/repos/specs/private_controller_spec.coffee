require("../../shared/specs/helpers")

describe "Repos Private Controller", ->
  originalGitHub = null
  beforeEach (done) ->
    originalGitHub = global.GitHub
    global.GitHub = ->
    global.GitHub.prototype.authenticate = ->
    global.GitHub.prototype.repos = {}
    global.GitHub.prototype.orgs = {}
    global.GitHub.prototype.repos.getAll = (params, callback) ->
      fs.readFile "#{Bot.root}/app/repos/specs/allRepos.json", (err, content) ->
        return done(err) if err
        callback(null, JSON.parse(content))

    global.GitHub.prototype.repos.createHook = (params, callback) ->
      callback(null, {})
    global.GitHub.prototype.repos.getHooks = (args, callback) ->
      callback(null, {})
    global.GitHub.prototype.repos.getFromUser = (args, callback) ->
      callback(null, {})
    global.GitHub.prototype.repos.getFromOrg = (args, callback) ->
      callback(null, {})
    global.GitHub.prototype.orgs.getFromUser = (args, callback) ->
      callback(null, [])

    req.host = 'localhost'
    req.hostname = 'localhost'

    Bot.db.users.save {
      provider:
        github:
          accessToken: '321'
          username: 'ghmonkey'
    }, (err, user) ->
      return done(err) if err
      req.user = user
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
        return null # Required to properly initialize prototype
      Bot.apps.repos.controller.private.index req, res, next

    it "should list all repos belonged to the user sorted by 'updated' date", (done) ->
      global.GitHub.prototype.repos.getAll = (args) ->
        args.sort.should.eql 'updated'
        done()
      Bot.apps.repos.controller.private.index req, res, next

    it "should list all organizations the user included in", (done) ->
      global.GitHub.prototype.orgs.getFromUser = (args, callback) ->
        args.user.should.eql 'ghmonkey'
        callback(null, [{ login: 'monkeyOrg' }])
      res.render = (url, params) ->
        should.exist params.orgs
        params.orgs.map('login').should.eql ['ghmonkey', 'monkeyOrg']
        done()
      Bot.apps.repos.controller.private.index req, res, next

    it "should render index.jade template", (done) ->
      res.render = (template, params) ->
        template.should.eql "#{Bot.root}/app/repos/private/index.jade"
        done()
      Bot.apps.repos.controller.private.index req, res, next

    describe 'search', ->
      it "should return all repos of a currently logged in user if no search params provided", (done) ->
        global.GitHub.prototype.repos.getAll = (args, callback) ->
          callback(null, [{ login: 'bananas' }])
        global.GitHub.prototype.repos.getFromUser = (args, callback) ->
          throw new Error('Only current user\'s repos should be requested')
        global.GitHub.prototype.repos.getFromOrg = (args, callback) ->
          throw new Error('Only current user\'s repos should be requested')

        res.render = (template, params) ->
          params.repos.should.eql [{ login: 'bananas' }]
          done()
        Bot.apps.repos.controller.private.index req, res, next

      it "should return currently logged in user as selected account if no search params provided", (done) ->
        res.render = (template, params) ->
          should.exist params.selectedAccount
          params.selectedAccount.login.should.eql 'ghmonkey'
          done()
        Bot.apps.repos.controller.private.index req, res, next

      it "should return all repos by requested organization", (done) ->
        req.query.org = 'superband'
        global.GitHub.prototype.repos.getAll = (args, callback) ->
          throw new Error('Only requested organization\'s repos should be requested')
        global.GitHub.prototype.repos.getFromUser = (args, callback) ->
          throw new Error('Only requested organization\'s repos should be requested')
        global.GitHub.prototype.repos.getFromOrg = (args, callback) ->
          args.org.should.eql 'superband'
          callback(null, [{ login: 'monkeyrepo' }])

        res.render = (template, params) ->
          params.repos.should.eql [{ login: 'monkeyrepo' }]
          done()
        Bot.apps.repos.controller.private.index req, res, next

      it "should return requested organization as selected account", (done) ->
        req.query.org = 'superband'
        global.GitHub.prototype.orgs.getFromUser = (args, callback) ->
          callback(null, [{ login: 'SuperBand' }])
        res.render = (template, params) ->
          params.selectedAccount.login.should.eql 'SuperBand'
          done()
        Bot.apps.repos.controller.private.index req, res, next

  describe 'create', ->
    beforeEach (done) ->
      req.body.repo = full_name: 'monkey/awesome', name: 'awesome', owner: { login: 'monkeymaster' }
      done()

    it "should authorize on github", (done) ->
      global.GitHub.prototype.authenticate = (args) ->
        args.type.should.eql 'oauth'
        args.token.should.eql '321'
        done()
        return null # Required to properly initialize prototype
      Bot.apps.repos.controller.private.create req, res, next

    it "should create github hooks", (done) ->
      global.GitHub.prototype.repos.createHook = (args, callback) ->
        args.should.eql {
          user: 'monkeymaster'
          repo: 'awesome'
          name: 'web'
          config:
            url: "http://localhost/pulls/github/callback"
            'content-type': 'application/json'
          events: ['pull_request']
          active: true
        }
        done()
        return null
      Bot.apps.repos.controller.private.create req, res, next

    it "should store the repo in database", (done) ->
      req.body.repo =
        id: 456789
        name: 'naggybot'
        full_name: 'monkey/naggybot'
        owner:
          login: 'monkeymaster'

      res.redirect = (url) ->
        Bot.db.repos.find('provider.github.name': 'naggybot').toArray (err, repos) ->
          return next(err) if err
          should.exist repos.first()
          Object.select(repos.first(), ['active', 'user', 'provider']).should.eql
            active: true
            user: req.user._id
            provider:
              github:
                id: 456789
                name: 'naggybot'
                full_name: 'monkey/naggybot'
                owner:
                  login: 'monkeymaster'
          done()

      Bot.apps.repos.controller.private.create req, res, next

    it "should set successfull flash message", (done) ->
      req.body.repo =
        id: 456789
        name: 'naggybot'
        full_name: 'monkey/naggybot'
        owner:
          login: 'monkeymaster'

      req.flash = (type, message) ->
        type.should.eql 'success'
        should.exist message
        done()

      Bot.apps.repos.controller.private.create req, res, next

    it "should redirect to repo#show page", (done) ->
      req.body.repo =
        id: 456789
        name: 'naggybot'
        full_name: 'monkey/naggybot'
        owner:
          login: 'monkeymaster'

      res.redirect = (url) ->
        should.exist url
        Bot.db.repos.find('provider.github.id': 456789).toArray (err, repos) ->
          return done(err) if err
          url.should.eql '/private/repos/' + repos.first()._id
          done()

      Bot.apps.repos.controller.private.create req, res, next

  describe 'del', ->
    beforeEach (done) ->
      Bot.db.repos.save {
        github_id: 456789
        provider: 'github'
        name: 'naggybot'
        full_name: 'monkey/naggybot'
        user: req.user._id
      }, (err, repo) ->
        return done(err) if err
        req.params.id = repo._id
        done()

    it "should authorize on github", (done) ->
      global.GitHub.prototype.authenticate = (args) ->
        args.type.should.eql 'oauth'
        args.token.should.eql '321'
        done()
        return null # Required to properly initialize prototype
      Bot.apps.repos.controller.private.del req, res, next

    it "should request all hooks attached to the repo", (done) ->
      global.GitHub.prototype.repos.getHooks = (args, callback) ->
        args.should.eql {
          user: 'ghmonkey'
          repo: 'monkey/naggybot'
          per_page: 100
        }
        done()
        return null
      Bot.apps.repos.controller.private.del req, res, next

    it "should remove all hooks created by naggybot", (done) ->
      global.GitHub.prototype.repos.getHooks = (args, callback) ->
        callback(null, [
          { id: 321, config: url: 'http://localhost/pulls/github/callback' },
          { id: 654, config: url: 'http://othersite.com/pulls/github/callback' },
          { id: 987, config: url: 'http://localhost/pulls/github/callback' }])
        return null

      removedHooks = []
      global.GitHub.prototype.repos.deleteHook = (args, callback) ->
        removedHooks.push args.id
        callback()

      res.json = (status, result) ->
        removedHooks.should.eql [321, 987]
        done()
      Bot.apps.repos.controller.private.del req, res, next

    it "should remove the repo from database", (done) ->
      res.json = (status, result) ->
        Bot.db.repos.findById result.repo._id, (err, repo) ->
          return done(err) if err
          repo.active.should.eql false
          done()
      Bot.apps.repos.controller.private.del req, res, next

