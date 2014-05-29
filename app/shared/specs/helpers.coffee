process.env.NODE_ENV = 'test'
chai = require('chai')

require('../../../server')
DatabaseCleaner = require('database-cleaner')

Object.merge global,
  databaseCleaner: new DatabaseCleaner('mongodb')
  should: chai.should()
  sinon: require 'sinon'

request = null
beforeEach (done) ->
  databaseCleaner.clean Bot.db, (err) ->
    return done(err) if(err)

    request = global.request
    global.req =
      params: {}
      query: {}
      headers: {}
      body: {}
      flash: ->

    global.res =
      render: ->
      redirect: ->
      setHeader: ->
      json: ->

    global.next = (err) -> throw err if err
    done()

afterEach (done) ->
  global.request = request
  done()

global.shouldHaveCreatedAt = (collection) ->
  it "should store createdAt when saved for first time", (done) ->
    Bot.db[collection].save { something: 'Ya!' }, (err, record) ->
      should.exist(record.createdAt)
      done()

  it "should not refresh createdAt if already provided", (done) ->
    time = (1).hourFromNow()
    Bot.db[collection].save { some: 'Yo!', createdAt: time }, (err, record) ->
      return done(err) if err
      record.createdAt.should.eql(time)
      done()

global.shouldHaveUpdatedAt = (collection) ->
  it "should always insert updatedAt", (done) ->
    time = (1).hourFromNow()
    Bot.db[collection].save { some: 'Yo!', updatedAt: time }, (err, record) ->
      return done(err) if err
      should.exist(record.updatedAt)
      record.updatedAt.should.not.eql(time)
      done()

global.shouldHaveRoutes = (routes, user, collection) ->
  app = null
  beforeEach ->
    app = express()
    app.apps = Object.clone(Bot.apps, true)

  Object.keys(routes).each (key) ->
    [method, url] = key.split(' ')
    [collection, controller, action] = routes[key].split('.')
    it "#{method.toUpperCase()} #{url} should match #{routes[key]}", (done) ->
      app.apps[collection].controller[controller][action] = -> done()
      app.apps[collection].routes.route(app)
      app.handle Object.merge(req, { method: method, url: url, user: user }), res, next

global.shouldNotHaveRoutes = (routes, user, collection) ->
  throw new Error('Routes are required as a first param') unless routes
  throw new Error('Collection is required as a third param') unless collection
  app = null
  beforeEach ->
    app = express()
    app.apps = Object.clone(Bot.apps, true)

  routes.each (route) ->
    [method, url] = route.split(' ')
    it "#{method.toUpperCase()} #{url} should return error 401", (done) ->
      app.apps[collection].routes.route(app)
      app.handle Object.merge(req, { method: method, url: url }), res, (err) ->
        err.should.eql new Error(401)
        done()

global.testPagingFor = (params) ->
  collection = params.collection
  action = params.action or "index"
  sort = params.sort or "createdAt"
  beforeEach (done) ->
    async.times 150, ((index, next) ->
      entity = title: index
      entity[sort] = Date.create(index)
      Bot.db[collection].save entity, (err, result) ->
        return done(err)  if err
        next()
    ), done

  it "should render 100 entities only", (done) ->
    res.render = (template, options) ->
      options.data.length.should.eql 100
      done()
    Bot.apps[collection].controller.admin[action] req, res, next

  it "should show 0 page by default", (done) ->
    res = render: (view, params) ->
      params.data.first()[sort].should.eql Date.create(149)
      done()
    Bot.apps[collection].controller.admin[action] req, res, next

  it "should return total number of entities", (done) ->
    res.render = (view, params) ->
      params.total.should.eql 150
      done()
    Bot.apps[collection].controller.admin[action] req, res, next

  it "should render requested page", (done) ->
    req.query = page: "1"
    res.render = (view, params) ->
      params.data.length.should.eql 50
      done()
    Bot.apps[collection].controller.admin[action] req, res, next

  it "should return currently selected page", (done) ->
    req.query = page: "1"
    res.render = (view, params) ->
      params.page.should.eql 1
      done()
    Bot.apps[collection].controller.admin[action] req, res, next

