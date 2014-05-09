require "../../shared/specs/helpers"

describe "User", ->
  describe 'skin save', ->
    shouldHaveCreatedAt('users')
    shouldHaveUpdatedAt('users')

    describe "Keywords", ->
      fromText = null
      beforeEach ->
        fromText = Skin.db.keywords.fromText

      afterEach ->
        Skin.db.keywords.fromText = fromText

      it "should call keywords.fromText on username", (done) ->
        Skin.db.keywords.fromText = (text, callback) ->
          text.should.eql "Monkey Coder monkey@zoo.com"
          fromText text, callback

        Skin.db.users.save
          username: "Monkey Coder"
          email: "monkey@zoo.com"
        , (err, user) ->
          user.keywords.should.eql [
            "monkey"
            "coder"
            "zoo"
            "com"
          ]
          done()

      it "should skip username if not specified", (done) ->
        Skin.db.users.save
          email: "monkey@zoo.com"
        , (err, user) ->
          user.keywords.should.eql [
            "monkey"
            "zoo"
            "com"
          ]
          done()

  describe "autocomplete", ->
    beforeEach (done) ->
      async.each [
        {
          username: "Monkey Coder"
          email: "monkey@coder.com"
        }
        {
          username: "Orangutan"
          email: "orangutan@monkey.com"
        }
      ], ((user, next) ->
        Skin.db.users.save user, next
      ), done

    it "should return empty array if no text provided", (done) ->
      Skin.db.users.autocomplete "", (err, users) ->
        should.not.exist err
        users.should.eql []
        done()

    it "should find user by if term is metioned in display name and / or email", (done) ->
      Skin.db.users.autocomplete "Coder", (err, users) ->
        should.not.exist err
        users.length.should.eql 1
        users.first().username.should.eql "Monkey Coder"
        done()

    it "should find user by if term is metioned in display name and / or email", (done) ->
      Skin.db.users.autocomplete "Monkey", (err, users) ->
        should.not.exist err
        users.length.should.eql 2
        users[1].email.should.eql "orangutan@monkey.com"
        done()

    it "should find user by full email", (done) ->
      Skin.db.users.autocomplete "monkey@coder.com", (err, users) ->
        should.not.exist err
        users.length.should.eql 1
        users[0].email.should.eql "monkey@coder.com"
        done()

  describe "validate", ->
    it "should return error on username if username is absent", (done) ->
      Skin.db.users.validate {}, (err, results) ->
        should.exist results.username
        done()

    it "should return error on password if password is absent", (done) ->
      Skin.db.users.validate {}, (err, results) ->
        should.exist results.password
        done()

    it "should return error on email if email doesn't look like email", (done) ->
      Skin.db.users.validate
        username: 'monkey'
        email: "something"
      , (err, results) ->
        return done(err) if err
        should.exist results.email
        done()

    it "should not return eny errors if email does exist and look just ok", (done) ->
      Skin.db.users.validate
        email: "monkey@zoo.com"
        username: "Monkey Zilla"
        password: "secret"
      , (err, results) ->
        return done(err) if err
        results.should.eql {}
        done()

    it "should return an error if confirmation password does not match the password itself", (done) ->
      Skin.db.users.validate
        password: "secret"
        confirmationPassword: "supersecret"
      , (err, results) ->
        should.exist results.password
        done()

    it "should return an error if confirmation password does exist, but empty", (done) ->
      Skin.db.users.validate
        password: "secret"
        confirmationPassword: ""
      , (err, results) ->
        should.exist results.password
        done()

    it "should not return any errors if confirmation password does not exist at all", (done) ->
      Skin.db.users.validate
        password: "secret"
      , (err, results) ->
        should.not.exist results.confirmationPassword
        done()

  describe "hashPassword", ->
    it "should return immediately if password is undefined", (done) ->
      Skin.db.users.hashPassword `undefined`, (err, password) ->
        return done(err)  if err
        should.not.exist password
        done()

