require("../../shared/specs/helpers")

describe "User Admin Controller", ->
  shouldBeLikeIndex = (options) ->
    action = (options || {}).action || 'index'

    it "should render proper view", (done) ->
      res.render = (template, options) ->
        template.should.eql "#{Skin.root}/app/users/admin/index.jade"
        done()
      Skin.apps.users.controller.admin[action](req, res, next)

    it "should not fail if no users found", (done) ->
      Skin.db.users.remove (err) ->
        return done(err) if(err)
        res.render = (template, params) ->
          params.total.should.eql(0)
          params.data.length.should.eql(0)
          done()
        Skin.apps.users.controller.admin[action](req, res, next)

    it "should render csv if csv format specified", (done) ->
      req.params = { format: 'csv' }
      res.send = (text) ->
        text.split("\n").length.should.eql(150 + 1) # +1 for header
        done()

      Skin.apps.users.controller.admin[action](req, res, next)

  describe "index", ->
    testPagingFor(collection: 'users')
    shouldBeLikeIndex(action: 'index')

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (user, index) ->
          return params.data[index + 1] && user.createdAt.should.be.above(params.data[index + 1].createdAt)
        done()
      Skin.apps.users.controller.admin.index(req, res, next)

    it "should return correct tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql('all')
        done()
      Skin.apps.users.controller.admin.index(req, res, next)

  describe "active", ->
    testPagingFor(collection: 'users', action: 'active', sort: 'visitedAt')
    shouldBeLikeIndex(action: 'active')

    beforeEach (done) ->
      Skin.db.users.find({}).toArray (err, users) ->
        return done(err) if(err)
        async.each users, (user, next) ->
          user.access = true
          user.confirmedAt = Date.create()
          user.password = 'some'
          Skin.db.users.save user, (err) ->
            return done(err) if(err)
            next()
        , done

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (user, index) ->
          return params.data[index + 1] && user.visitedAt.should.be.above(params.data[index + 1].visitedAt)
        done()
      Skin.apps.users.controller.admin.active(req, res, next)

    it "should only show active users", (done) ->
      Skin.db.users.update { title: { $gt: 5 }}, { $set: { access: false }}, { multi: true }, (err) ->
        return done(err) if(err)
        res.render = (view, params) ->
          params.data.length.should.eql(6)
          params.total.should.eql(6)
          done()
        Skin.apps.users.controller.admin.active(req, res, next)

    it "should return correct tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql('active')
        done()
      Skin.apps.users.controller.admin.active(req, res, next)

  describe "blocked", ->
    testPagingFor(collection: 'users', action: 'blocked')
    shouldBeLikeIndex(action: 'blocked')

    beforeEach (done) ->
      Skin.db.users.update({}, { $set: { access: false }}, { multi: true }, done)

    it "should render proper view", (done) ->
      res.render = (template, options) ->
        template.should.eql(Skin.root + '/app/users/admin/index.jade')
        done()
      Skin.apps.users.controller.admin.blocked(req, res, next)

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (user, index) ->
          return params.data[index + 1] && user.createdAt.should.be.above(params.data[index + 1].createdAt)
        done()
      Skin.apps.users.controller.admin.blocked(req, res, next)

    it "should only show blocked users", (done) ->
      Skin.db.users.update { title: { $gt: 5 }}, { $set: { access: true }}, { multi: true }, (err) ->
        return done(err) if(err)
        res.render = (view, params) ->
          params.data.length.should.eql(6)
          params.total.should.eql(6)
          done()
        Skin.apps.users.controller.admin.blocked(req, res, next)

    it "should return tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql('blocked')
        done()
      Skin.apps.users.controller.admin.blocked(req, res, next)

  describe "search", ->
    testPagingFor(collection: 'users', action: 'search', sort: 'visitedAt')
    shouldBeLikeIndex(action: 'search')
    beforeEach (done) ->
      cursor = Skin.db.users.find({})
      user = null

      async.doWhilst (next) ->
        cursor.nextObject (err, u) ->
          return next(err) if(err)
          user = u
          return next() if(!user)
          user.username = user.title
          Skin.db.users.save(user, next)
      , ->
        return !!user
      , done

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (user, index) ->
          return params.data[index + 1] && user.visitedAt.should.be.above(params.data[index + 1].visitedAt)
        done()
      Skin.apps.users.controller.admin.search(req, res, next)

    it "should return correct tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql('search')
        done()
      Skin.apps.users.controller.admin.search(req, res, next)

    it "should only show users matching the search request", (done) ->
      req.query = { term: '2' }
      res.render = (template, params) ->
        params.data.length.should.eql(11)
        params.total.should.eql(11)
        done()
      Skin.apps.users.controller.admin.search(req, res, next)

    it "should provide term in params", (done) ->
      req.query = { term: 'monkey' }
      res.render = (template, params) ->
        params.term.should.eql('monkey')
        done()
      Skin.apps.users.controller.admin.search(req, res, next)

  describe "Show", ->
    user2show = null
    beforeEach (done) ->
      Skin.db.users.save { email: 'dmitry@skrinnik.com' }, (err, user) ->
        user2show = user
        req.params = { id: user2show._id.toString() }
        done()

    it "should select that concrete user", (done) ->
      res.render = (view, params) ->
        view.should.equal(Skin.root + "/app/users/admin/form.jade")
        params.man._id.should.eql(user2show._id)
        done()
      Skin.apps.users.controller.admin.show(req, res)

    it "should generate MD5 hash after user's email", (done) ->
      res.render = (view, params) ->
        params.man.emailmd5.should.eql('0a4d6346bd2f3ff7512d660efa1a2716')
        done()
      Skin.apps.users.controller.admin.show(req, res)

  describe "Update", ->
    user = null
    beforeEach (done) ->
      Skin.db.users.save {
          username: 'Monkey',
          email: 'monkey@picsio.com',
          access: false
        }, (err, result) ->
          return done(err) if err
          user = result
          req.body.user =
            username: 'Code Monkey',
            email: 'monkey@picsio.com',
            access: 'on'
          req.params.id = result._id
          done()

    it "should redirect to users list in case of successfull update", (done) ->
      res.redirect = ->
        Skin.db.users.findById user._id, (err, result) ->
          result.username.should.eql 'Code Monkey'
          result.email.should.eql 'monkey@picsio.com'
          result.access.should.eql(true)
          done()

      Skin.apps.users.controller.admin.update(req, res)

    it "should update user successfully", (done) ->
      res.redirect = (url) ->
        url.should.eql '/admin/users'
        done()
      Skin.apps.users.controller.admin.update(req, res)

  describe 'autocomplete', ->
    autocomplete = null
    beforeEach ->
      autocomplete = Skin.db.users.autocomplete
    afterEach ->
      Skin.db.users.autocomplete = autocomplete

    it 'should render all users from autocomplete to json', (done) ->
      Skin.db.users.autocomplete = (text, callback) ->
        callback null, [{ username: 'Monkey', email: 'monkey@coder.com' }, { email: 'godzilla@house.com' }]

      res.json = (st, data) ->
        data.users.length.should.eql(2)
        done()
      Skin.apps.users.controller.admin.autocomplete(req, res, next)

