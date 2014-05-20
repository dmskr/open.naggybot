require "../../shared/specs/helpers"

describe "Review", ->
  describe 'skin save', ->
    shouldHaveCreatedAt('reviews')
    shouldHaveUpdatedAt('reviews')

    it "should always save review in pending status if no other status is specified", (done) ->
      Bot.db.reviews.save { type: 'some' }, (err, review) ->
        return done(err) if err
        should.exist review
        review.status.should.eql 'pending'
        done()

    it "should save review status as is if any provided", (done) ->
      Bot.db.reviews.save { status: 'inprogress' }, (err, review) ->
        return done(err) if(err)
        should.exist(review)
        review.status.should.eql('inprogress')
        done()

  describe "expireAll", ->
    it "should expire any review created more than 10 minutes ago in not completed status still", (done) ->
      Bot.db.reviews.save
        status: "inprogress"
        createdAt: (11).minutesAgo()
      , (err, review) ->
        return done(err) if err
        Bot.db.reviews.expireAll (err) ->
          return done(err) if err
          Bot.db.reviews.findById review._id, (err, review) ->
            return done(err) if err
            review.status.should.eql "expired"
            should.exist review.expiredAt
            done()

    it "should ignore all completed reviews", (done) ->
      Bot.db.reviews.save
        status: "completed"
        createdAt: (11).minutesAgo()
      , (err, review) ->
        return done(err) if err
        Bot.db.reviews.expireAll ->
          return done(err) if err
          Bot.db.reviews.findById review._id, (err, review) ->
            return done(err) if err
            review.status.should.eql "completed"
            done()

    it "should ignore all non completed reviews created less than 10 minutes ago", (done) ->
      Bot.db.reviews.save
        status: "inprogress"
        createdAt: (9).minutesAgo()
      , (err, review) ->
        return done(err) if err
        Bot.db.reviews.expireAll ->
          return done(err) if err
          Bot.db.reviews.findById review._id, (err, review) ->
            return done(err) if err
            review.status.should.eql "inprogress"
            done()

  describe 'executeAll', ->
    execute = null
    executedReviews = []
    beforeEach (done) ->
      reviews = [
        { status: 'inprogress' }
        { status: 'completed' }
        { status: 'completed' }
        { status: 'completed' }
        { status: 'error' }
      ]
      (15).times -> reviews.push({ status: 'pending' })
      async.each reviews, Bot.db.reviews.save, done
      execute = Bot.db.reviews.execute

      executedReviews = []
      Bot.db.reviews.execute = (review, callback) ->
        executedReviews.push review
        callback(null, review)

    afterEach (done) ->
      Bot.db.reviews.execute = execute
      done()

    it "should find and execute all reviews in pending status", (done) ->
      Bot.db.reviews.executeAll {}, (err, reviews) ->
        return done(err) if err
        executedReviews.length.should.eql 15
        executedReviews.all((r) -> r.status == 'pending').should.eql true
        done()

    it "should limit reviews number by 'limit' option", (done) ->
      Bot.db.reviews.executeAll { limit: 10 }, (err, reviews) ->
        return done(err) if err
        executedReviews.length.should.eql 10
        executedReviews.all((r) -> r.status == 'pending').should.eql true
        done()

