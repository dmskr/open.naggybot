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

  describe 'execute', ->
    [pull, analyze, push] = [null, null, null]

    beforeEach (done) ->
      [pull, analyze, push] = [Bot.db.reviews.pull, Bot.db.reviews.analyze, Bot.db.reviews.push]
      Bot.db.reviews.pull = Bot.db.reviews.analuze = Bot.db.reviews.push = (review, callback) ->
        callback(null, review)
      done()

    afterEach (done) ->
      [Bot.db.reviews.pull, Bot.db.reviews.analuze, Bot.db.reviews.push] = [pull, analyze, push]
      done()

    it "should pull data to review first", (done) ->
      Bot.db.reviews.pull = (review, callback) ->
        should.exist review
        done()
      Bot.db.reviews.analyze = Bot.db.reviews.push = (review, callback) ->
        throw new Error('Review#pull should be called first')
      Bot.db.reviews.execute status: 'pending', (err, review) ->

    it "should immediately change review status to inprogress", (done) ->
      Bot.db.reviews.pull = (review, callback) ->
        should.exist review
        should.exist review._id
        review.status.should.eql 'inprogress'
        done()

      Bot.db.reviews.execute status: 'pending', (err, review) ->

    it "should analyze data received from pull", (done) ->
      Bot.db.reviews.pull = (review, callback) ->
        callback null, review
      Bot.db.reviews.analyze = (review, callback) ->
        should.exist review
        done()
      Bot.db.reviews.push = (review, callback) ->
        throw new Error('Review#analyze should be called first')
      Bot.db.reviews.execute status: 'pending', (err, review) ->

    it "should push resul of an analyze", (done) ->
      Bot.db.reviews.push = (review, callback) ->
        should.exist review
        done()
      Bot.db.reviews.pull = Bot.db.reviews.analyze = (review, callback) ->
        callback null, review
      Bot.db.reviews.execute status: 'pending', (err, review) ->

  #describe "pull", ->
    #httprequest = null
    #review = null
    #temp = null
    #writeStream = null
    #beforeEach (done) ->
      #httprequest = global.request
      #temp = global.tmp
      #writeStream = fs.createWriteStream
      #fs.readFile Bot.root + '/app/reviews/specs/pullRequest.json', (err, content) ->
        #return done(err) if err
        #review =
          #github:
            #pull_request: JSON.parse(content)
        #done()

    #afterEach (done) ->
      #global.request = httprequest
      #global.tmp = temp
      #fs.createWriteStream = writeStream
      #done()

    #it "should get tarball of a reviewed pull request", (done) ->
      #global.request = (options) ->
        #should.exist options
        #should.exist options.url
        #options.url.should.eql 'https://api.github.com/repos/octocat/hello-world/tarball/6dcb09b5b57875f334f61aebed695e2e4193db5e'
        #should.exist options.headers
        #options.headers['User-Agent'].should.eql 'NodeJS HTTP Client'
        #done()

      #Bot.db.reviews.pull review, (err, review) ->

    #it "should pipe to correct file path and store the path in review.pull", (done) ->
      #fs.createWriteStream = (path) ->
        #path.should.eq '/some/path/ar.tar'
        #return 'write stream'

      #global.request = (options) ->
        #return {
          #pipe: (fileStream) ->
            #fileStream.should.eql 'write stream'
            #done()
        #}

      #tmp.tmpName = (options, callback) ->
        #options.keep.should.eql true
        #callback null, '/some/path'

      #Bot.db.reviews.pull review, (err, review) ->

