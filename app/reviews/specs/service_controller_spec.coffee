require("../../shared/specs/helpers")

describe "Reviews Service Controller", ->
  describe "create", ->
    beforeEach (done) ->
      req.headers['x-github-event'] = 'pull_request'
      fs.readFile Bot.root + '/app/reviews/specs/samples/pullRequestEvent.json', (err, content) ->
        req.body.payload = content
        done()

    it "should pass through if github event not equal to ping or pull_request", (done) ->
      async.each [null, 'some'], (event, callback) ->
        req.headers['x-github-event'] = event
        Bot.apps.reviews.controller.service.create req, res, callback
      , done

    it "should allow the 'ping' event as well", (done) ->
      req.headers['x-github-event'] = 'ping'
      res.json = -> done()

      Bot.apps.reviews.controller.service.create req, res, next

    it "should not create any review objects on ping event", (done) ->
      req.headers['x-github-event'] = 'ping'
      res.json = ->
        Bot.db.reviews.find().limit(1).toArray (err, reviews)->
          return done(err) if err
          should.not.exist reviews.first()
          done()
      Bot.apps.reviews.controller.service.create req, res, next

    it "should create review in database", (done) ->
      res.json = ->
        Bot.db.reviews.find().limit(1).toArray (err, reviews)->
          return done(err) if err
          should.exist reviews
          should.exist reviews.first()
          done()

      Bot.apps.reviews.controller.service.create req, res, next

    it "should place everything received into the github property", (done) ->
      res.json = ->
        Bot.db.reviews.find().limit(1).toArray (err, reviews)->
          return done(err) if err
          should.exist reviews
          should.exist reviews.first()
          should.exist reviews.first().github
          should.exist Object.select(reviews.first().github, 'action', 'number').should.eql {
            action: 'synchronize'
            number: 3
          }
          done()

      Bot.apps.reviews.controller.service.create req, res, next

