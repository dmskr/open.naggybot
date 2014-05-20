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

  describe "expire", ->
    it "should expire any review created more than 10 minutes ago in not completed status still", (done) ->
      Bot.db.reviews.save
        status: "inprogress"
        createdAt: (11).minutesAgo()
      , (err, review) ->
        res.json = (st, data) ->
          Bot.db.reviews.findById review._id, (err, review) ->
            review.status.should.eql "expired"
            done()
        Bot.apps.reviews.controller.service.expire req, res, next

    it "should ignore all completed reviews", (done) ->
      Bot.db.reviews.save
        status: "completed"
        createdAt: (11).minutesAgo()
      , (err, review) ->
        res.json = (st, data) ->
          Bot.db.reviews.findById review._id, (err, review) ->
            review.status.should.eql "completed"
            done()
        Bot.apps.reviews.controller.service.expire req, res, next

    it "should ignore all non completed reviews created less than 10 minutes ago", (done) ->
      Bot.db.reviews.save
        status: "inprogress"
        createdAt: (9).minutesAgo()
      , (err, review) ->
        res.json = (st, data) ->
          Bot.db.reviews.findById review._id, (err, review) ->
            review.status.should.eql "inprogress"
            done()
        Bot.apps.reviews.controller.service.expire req, res, next

