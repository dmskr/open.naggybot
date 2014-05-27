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

  describe "pull", ->
    [review, temp, child_exec, findByRepo, lrequest] = [null, null, null, null, null]
    beforeEach (done) ->
      temp = global.tmp
      child_exec = global.exec
      findByRepo = Bot.db.users.findByRepo
      Bot.db.users.findByRepo = (repo, callback) ->
        callback(null, { github: { accessToken: '567890' }})

      lrequest = global.request
      global.request = (options, callback) -> callback(null, {}, '')
      global.exec = (command, callback) -> callback(null)

      fs.readFile Bot.root + '/app/reviews/specs/pullRequest.json', (err, content) ->
        return done(err) if err
        review =
          github:
            number: 2
            pull_request: JSON.parse(content)
        done()

    afterEach (done) ->
      global.tmp = temp
      global.exec = child_exec
      global.request = lrequest
      Bot.db.users.findByRepo = findByRepo
      done()

    it "should get tarball of a reviewed pull request", (done) ->
      global.exec = (command, callback) ->
        matches = command.match(/^wget -O (\S+) .+/)
        should.exist matches
        done()
      Bot.db.reviews.pull review, (err, review) ->

    it "should download a tarbar into existing directory", (done) ->
      global.exec = (command, callback) ->
        matches = command.match(/^wget -O (\S+) .+/)
        should.exist matches[1]
        fs.exists pathUtil.dirname(matches[1]), (exists) ->
          exists.should.eql true
          done()
      Bot.db.reviews.pull review, (err, review) ->

    it "should store pull.path & pull.archive for future use", (done) ->
      global.exec = (command, callback) ->
        matches = command.match(/^wget -O (\S+) .+/)
        should.exist review.pull
        should.exist review.pull.path
        review.pull.archive.should.eql matches[1]
        review.pull.path.should.eql pathUtil.dirname(matches[1])
        done()
      Bot.db.reviews.pull review, (err, review) ->

    it "should wget the correct url", (done) ->
      global.exec = (command, callback) ->
        matches = command.match(/^wget -O (\S+) (.+)/)
        should.exist matches[2]
        matches[2].should.eql 'https://api.github.com/repos/octocat/Hello-World/tarball/6dcb09b5b57875f334f61aebed695e2e4193db5e?access_token=567890'
        done()
      Bot.db.reviews.pull review, (err, review) ->

    it "should extract tarball into sources folder", (done) ->
      global.exec = (command, callback) ->
        return callback(null) if command.match /^wget/
        command.should.eql "tar -xf #{review.pull.archive} -C #{review.pull.path}/source --strip-components=1"
        done()
      Bot.db.reviews.pull review, (err, review) ->

    it "should request the diff", (done) ->
      global.request = (options, callback) ->
        options.headers.should.eql { 'Accept': 'application/vnd.github.diff', 'User-Agent': 'NodeJS HTTP Client' }
        options.url.should.eql "https://api.github.com/repos/octocat/Hello-World/pulls/2?access_token=567890"
        done()
      Bot.db.reviews.pull review, (err, review) ->

    it "should store returned diff in a file", (done) ->
      global.request = (options, callback) ->
        callback null, {}, 'this is the diff'

      Bot.db.reviews.pull review, (err, review) ->
        should.exist review.pull.diff
        review.pull.diff.should.eql review.pull.path + '/git.diff'
        fs.readFile review.pull.diff, (err, content) ->
          return done(err) if err
          content.toString().should.eql 'this is the diff'
          done()

  describe 'analyze', ->
    it "should run coffeelint on all coffee files", (done) ->
      done()

