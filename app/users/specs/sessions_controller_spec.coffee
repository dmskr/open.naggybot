require("../../shared/specs/helpers")

describe "Sessions Controller", ->
  describe "new", ->
    it "should render login template", (done) ->
      res.render = (template) ->
        template.should.eql Bot.root + '/app/users/public/login.jade'
        done()
      Bot.apps.users.controller.sessions.new(req, res, next)

  describe "create", ->

  describe "del", ->
    it "should call req.logout to remove user's cookie", (done) ->
      req.logout = done
      Bot.apps.users.controller.sessions.del req, res, next

    it "should redirect back to root", (done) ->
      req.logout = ->
      res.redirect = (url) ->
        url.should.eql '/'
        done()
      Bot.apps.users.controller.sessions.del req, res, next

  describe 'authgithub', ->
    profile = null
    accessToken = '7ad7e86cc010dcf94d9b1bf0e51ab7d9fe8ade8c'
    refreshToken = '7ad7e86cc010dcf94d9b1bg0e51ac7d9te84fe6a'

    before (done) ->
      fs.readFile "#{Bot.root}/app/users/specs/profileGitHub.json", (err, content) ->
        return done(err) if err
        profile = JSON.parse(content)
        done()

    describe 'existing user', ->
      [existing, returned, updated] = [null, null, null]
      before (done) ->
        Bot.db.users.save { provider: { github: id: 123 }}, (err, result) ->
          return done(err) if err
          existing = result
          Bot.apps.users.controller.sessions.authGitHub accessToken, refreshToken, profile, (err, result) ->
            return done(err) if err
            returned = result
            Bot.db.users.findById returned._id, (err, result) ->
              return done(err) if err
              updated = result
              done()

      it "should return existing user by github profile id", (done) ->
          should.exist(returned)
          should.exist(returned._id)
          returned._id.should.eql existing._id
          done()

      it "should return updated user", ->
        returned.should.eql updated
      
      describe "should update", ->
        it "displayName", ->
          updated.provider.github.displayName.should.eql 'Naggy Bot'
        it 'username', ->
          updated.provider.github.username.should.eql 'naggybot'
        it 'emails', ->
          updated.provider.github.emails.should.eql []
        it 'avatar_url', ->
          updated.provider.github.avatar_url.should.eql 'https://avatars.githubusercontent.com/u/7523890?'
        it 'gravatar_id', ->
          updated.provider.github.gravatar_id.should.eql 'c05935237e2c7cc96f037085637e90b0'
        it "accessToken", ->
          updated.provider.github.accessToken.should.eql accessToken
        it "refreshToken", ->
          updated.provider.github.refreshToken.should.eql refreshToken

    describe 'new user', ->
      [returned, updated] = [null, null, null]
      before (done) ->
        Bot.apps.users.controller.sessions.authGitHub accessToken, refreshToken, profile, (err, result) ->
          return done(err) if err
          returned = result
          Bot.db.users.findById returned._id, (err, result) ->
            return done(err) if err
            updated = result
            done()

      it "should be created in database", ->
        should.exist updated
        should.exist updated._id

      it "should return created user", ->
        should.exist returned
        should.exist returned._id
        returned.should.eql updated

      describe "should savee", ->
        it "github id", ->
          updated.provider.github.id.should.eql 123
        it "displayName", ->
          updated.provider.github.displayName.should.eql 'Naggy Bot'
        it 'username', ->
          updated.provider.github.username.should.eql 'naggybot'
        it 'emails', ->
          updated.provider.github.emails.should.eql []
        it 'avatar_url', ->
          updated.provider.github.avatar_url.should.eql 'https://avatars.githubusercontent.com/u/7523890?'
        it 'gravatar_id', ->
          updated.provider.github.gravatar_id.should.eql 'c05935237e2c7cc96f037085637e90b0'
        it "accessToken", ->
          updated.provider.github.accessToken.should.eql accessToken
        it "refreshToken", ->
          updated.provider.github.refreshToken.should.eql refreshToken

