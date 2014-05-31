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
      callback(null, [])
    global.GitHub.prototype.repos.getHooks = (args, callback) ->
      callback(null, [])
    global.GitHub.prototype.repos.getFromUser = (args, callback) ->
      callback(null, [])
    global.GitHub.prototype.repos.getFromOrg = (args, callback) ->
      callback(null, [])
    global.GitHub.prototype.orgs.getFromUser = (args, callback) ->
      callback(null, [])

    req.host = 'localhost'
    req.hostname = 'localhost'

    Bot.db.users.save {
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
        should.exist params.accounts
        params.accounts.map('login').should.eql ['ghmonkey', 'monkeyOrg']
        done()
      Bot.apps.repos.controller.private.index req, res, next

    it "should mark all organizations as orgs and users as 'user'", (done) ->
      global.GitHub.prototype.orgs.getFromUser = (args, callback) ->
        args.user.should.eql 'ghmonkey'
        callback(null, [{ login: 'monkeyOrg' }])
      res.render = (url, params) ->
        should.exist params.accounts
        params.accounts.map('type').should.eql ['user', 'organization']
        done()
      Bot.apps.repos.controller.private.index req, res, next

    it "should mark all nagged repos of the user stored in local db as those", (done) ->
      Bot.db.repos.save { user: req.user._id, github: { name: 'bananas', owner: { login: 'monkey' }}, active: true }, (err) ->
        return done(err) if err

        global.GitHub.prototype.repos.getAll = (args, callback) ->
          callback(null, [{ name: 'bananas', owner: { login: 'monkey' }}])

        res.render = (template, params) ->
          params.repos.should.eql [{ name: 'bananas', owner: { login: 'monkey' }, nagging: true }]
          done()

        Bot.apps.repos.controller.private.index req, res, next

    it "should not mark repos of the user not stored in local db as those", (done) ->
      global.GitHub.prototype.repos.getAll = (args, callback) ->
        callback(null, [{ name: 'bananas', owner: { login: 'monkey' }}])

      res.render = (template, params) ->
        params.repos.should.eql [{ name: 'bananas', owner: { login: 'monkey' }}]
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
        req.query.organization = 'superband'
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
        req.query.organization = 'superband'
        global.GitHub.prototype.orgs.getFromUser = (args, callback) ->
          callback(null, [{ login: 'SuperBand' }])
        res.render = (template, params) ->
          params.selectedAccount.login.should.eql 'SuperBand'
          done()
        Bot.apps.repos.controller.private.index req, res, next

  describe 'create', ->
    beforeEach (done) ->
      req.body.repo =
        name: 'awesome'
        owner:
          login: 'monkeymaster'
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
            url: "http://localhost:8082/pulls/github/callback"
            'content-type': 'application/json'
          events: ['pull_request']
          active: true
        }
        done()
        return null
      Bot.apps.repos.controller.private.create req, res, next

    it "should ignore 'hook already exists' message from github if any", (done) ->
      global.GitHub.prototype.repos.createHook = (args, callback) ->
        fs.readFile Bot.root + '/app/repos/specs/hookAlreadyExists.json', (err, content) ->
          return done(err) if err
          callback JSON.parse(content)
        return null

      res.redirect = ->
        done()

      Bot.apps.repos.controller.private.create req, res, next

    it "should store the repo in database", (done) ->
      res.redirect = (url) ->
        Bot.db.repos.find('github.name': 'awesome', 'github.owner.login': 'monkeymaster').toArray (err, repos) ->
          return next(err) if err
          should.exist repos.first()
          Object.select(repos.first(), ['active', 'user', 'github']).should.eql
            active: true
            user: req.user._id
            github:
              name: 'awesome'
              owner:
                login: 'monkeymaster'
          done()

      Bot.apps.repos.controller.private.create req, res, next

    it "should update existing if repo with the same name & owner belonged to the same user already exist in database", (done) ->
      Bot.db.repos.save { github: req.body.repo, user: req.user._id, active: false }, (err) ->
        return done(err) if err

        res.redirect = (url) ->
          Bot.db.repos.find('github.name': 'awesome', 'github.owner.login': 'monkeymaster').toArray (err, repos) ->
            return next(err) if err
            repos.length.should.eql 1
            Object.select(repos.first(), ['active', 'user', 'github']).should.eql
              active: true
              user: req.user._id
              github:
                name: 'awesome'
                owner:
                  login: 'monkeymaster'
            done()

        Bot.apps.repos.controller.private.create req, res, next

    it "should set successfull flash message", (done) ->
      req.flash = (type, message) ->
        type.should.eql 'success'
        should.exist message
        done()

      Bot.apps.repos.controller.private.create req, res, next

    it "should redirect to repo#index page", (done) ->
      res.redirect = (url) ->
        should.exist url
        url.should.eql '/private/repos/'
        done()

      Bot.apps.repos.controller.private.create req, res, next

  describe 'del', ->
    repo = null
    beforeEach (done) ->
      Bot.db.repos.save {
        user: req.user._id
        github:
          name: 'naggybot'
          owner:
            login: 'monkey'
        active: true
      }, (err, result) ->
        return done(err) if err
        repo = result
        req.params.name = 'naggybot'
        req.params.owner = 'monkey'
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
          user: 'monkey'
          repo: 'naggybot'
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

      res.redirect = ->
        removedHooks.should.eql [321, 987]
        done()
      Bot.apps.repos.controller.private.del req, res, next

    it "should mark the repo as inactive", (done) ->
      res.redirect = ->
        Bot.db.repos.findById repo._id, (err, repo) ->
          return done(err) if err
          repo.active.should.eql false
          done()
      Bot.apps.repos.controller.private.del req, res, next

    it "should set successfull flash message", (done) ->
      req.flash = (type, message) ->
        type.should.eql 'success'
        should.exist message
        done()

      Bot.apps.repos.controller.private.del req, res, next

    it "should redirect to repo#index page", (done) ->
      res.redirect = (url) ->
        should.exist url
        url.should.eql '/private/repos'
        done()

      Bot.apps.repos.controller.private.del req, res, next


