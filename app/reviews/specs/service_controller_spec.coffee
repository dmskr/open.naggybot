require("../../shared/specs/helpers")

describe "Reviews Service Controller", ->
  describe "create", ->
    beforeEach (done) ->
      req.headers['X-GitHub-Event'] = 'PullRequestEvent'
      fs.readFile Bot.root + '/app/reviews/specs/pullRequestEvent.json', (err, content) ->
        req.body = JSON.parse(content)
        done()

    it "should pass through if github event not equal to PullRequestEvent or pull_request", (done) ->
      async.each [null, 'some'], (event, callback) ->
        req.headers['X-GitHub-Event'] = event
        Bot.apps.reviews.controller.service.create req, res, callback
      , done

    it "should create review in database", (done) ->
      res.json = ->
        Bot.db.reviews.find().limit(1).toArray (err, reviews)->
          return done(err) if err
          should.exist reviews
          should.exist reviews.first()
          done()

      Bot.apps.reviews.controller.service.create req, res, next


