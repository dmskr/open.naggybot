process.env.NODE_ENV = 'test'
should = require('should')

require('../../../server')
DatabaseCleaner = require('database-cleaner')

Object.merge global,
  databaseCleaner: new DatabaseCleaner('mongodb')
  should: require('should')

request = null
beforeEach (done) ->
  databaseCleaner.clean Skin.db, (err) ->
    return done(err) if(err)

    request = global.request
    global.req =
      params: {}
      query: {}
      body: {}
      flash: ->

    global.res =
      render: ->
      redirect: ->

    global.next = (err) -> throw err if err
    done()

afterEach (done) ->
  global.request = request
  done()

global.shouldHaveCreatedAt = (collection) ->
  it "should store createdAt when saved for first time", (done) ->
    Skin.db[collection].save { something: 'Ya!' }, (err, record) ->
      should.exist(record.createdAt)
      done()

  it "should not refresh createdAt if already provided", (done) ->
    time = (1).hourFromNow()
    Skin.db[collection].save { some: 'Yo!', createdAt: time }, (err, record) ->
      return done(err) if err
      record.createdAt.should.eql(time)
      done()

global.shouldHaveUpdatedAt = (collection) ->
  it "should always insert updatedAt", (done) ->
    time = (1).hourFromNow()
    Skin.db[collection].save { some: 'Yo!', updatedAt: time }, (err, record) ->
      return done(err) if err
      should.exist(record.updatedAt)
      record.updatedAt.should.not.eql(time)
      done()

global.shouldHaveRoutes = (routes, user, collection) ->
  app = null
  beforeEach ->
    app = express()
    app.apps = Object.clone(Skin.apps, true)

  Object.keys(routes).each (key) ->
    [method, url] = key.split(' ')
    [collection, controller, action] = routes[key].split('.')
    it "#{method.toUpperCase()} #{url} should match #{routes[key]}", (done) ->
      app.apps[collection].controller[controller][action] = -> done()
      app.apps[collection].routes.route(app)
      app.router { method: method, url: url, user: user }, {}, ->

global.shouldNotHaveRoutes = (routes, user, collection) ->
  app = null
  beforeEach ->
    app = express()
    app.apps = Object.clone(Skin.apps, true)

  routes.each (route) ->
    [method, url] = route.split(' ')
    it "#{method.toUpperCase()} #{url} should return error 401", (done) ->
      app.apps[collection].routes.route(app)
      app.router { method: method, url: url }, {}, (err)->
        err.should.eql new Error(401)
        done()

