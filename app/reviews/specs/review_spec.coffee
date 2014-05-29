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
      [Bot.db.reviews.pull, Bot.db.reviews.analyze, Bot.db.reviews.push] = [pull, analyze, push]
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

      fs.readFile Bot.root + '/app/reviews/specs/samples/pullRequest.json', (err, content) ->
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
    [unidiffparse, adviserlint, thinkWhatYouSay, review, readFile] = [null, null, null, null, null]
    beforeEach (done) ->
      unidiffparse = Bot.apps.reviews.unidiff.parse
      adviserlint = Bot.apps.reviews.adviser.lint
      thinkWhatYouSay = Bot.db.reviews.thinkWhatYouSay
      readFile = fs.readFile

      Bot.apps.reviews.unidiff.parse = (diff, callback) -> callback null, [{ name: '3/4.coffee' }, {name: '1/2.coffee'}]
      Bot.apps.reviews.adviser.lint = (files, callback) -> callback null, 'lint report'
      Bot.db.reviews.thinkWhatYouSay = (diff, report, callback) -> callback null, 'final report'
      fs.readFile = (path, callback) -> callback null, ''

      Bot.db.reviews.save { pull: diff: 'diff/path' }, (err, result) ->
        return done(err) if err
        review = result
        done()

    afterEach (done) ->
      Bot.apps.reviews.unidiff.parse = unidiffparse
      Bot.apps.reviews.adviser.lint = adviserlint
      Bot.db.reviews.thinkWhatYouSay = thinkWhatYouSay
      fs.readFile = readFile
      done()

    it "should parse diff stored in the review", (done) ->
      fs.readFile = (path, callback) ->
        path.should.eql 'diff/path'
        callback null, 'this is a diff'

      Bot.apps.reviews.unidiff.parse = (diff, callback) ->
        diff.should.eql 'this is a diff'
        done()
      Bot.db.reviews.analyze review, ->

    it "should store the unidiff artifacts to analyze section", (done) ->
      Bot.db.reviews.analyze review, (err, review) ->
        return done(err) if err
        Bot.db.reviews.findById review._id, (err, review) ->
          return done(err) if err
          should.exist review.analyze
          should.exist review.analyze.unidiff
          review.analyze.unidiff.should.eql [{ name: '3/4.coffee' }, { name: '1/2.coffee'}]
          done()

    it "should run adviser on files present on the diff", (done) ->
      Bot.apps.reviews.unidiff.parse = (diff, callback) ->
        callback null, [{ name: '3/4.coffee' }, {name: '1/2.coffee'}]
      Bot.apps.reviews.adviser.lint = (files, callback) ->
        files.should.eql ['3/4.coffee', '1/2.coffee']
        done()
      Bot.db.reviews.analyze review, (err, review) ->

    it "should store adviser artifacts into the review object", (done) ->
      Bot.apps.reviews.adviser.lint = (files, callback) ->
        callback null, 'adviser result'
      Bot.db.reviews.analyze review, (err, review) ->
        return done(err) if err
        Bot.db.reviews.findById review._id, (err, review) ->
          return done(err) if err
          should.exist review.analyze
          review.analyze.lint.should.eql 'adviser result'
          done()

    it "should run thinkWhatYouSay on result of diff parsing and sources advising", (done) ->
      Bot.db.reviews.thinkWhatYouSay = (diff, report, callback) ->
        diff.should.eql [{ name: '3/4.coffee' }, { name: '1/2.coffee' }]
        report.should.eql 'lint report'
        done()
      Bot.db.reviews.analyze review, (err, review) ->

    it "should store the final report to analyze section", (done) ->
      Bot.db.reviews.analyze review, (err, review) ->
        return done(err) if err
        Bot.db.reviews.findById review._id, (err, review) ->
          return done(err) if err
          should.exist review.analyze
          review.analyze.report.should.eql 'final report'
          done()

  describe 'thinkWhatYouSay', ->
    [diff, comments] = [null, null]
    beforeEach (done) ->
      comments = []
      fs.readFile Bot.root + '/app/reviews/specs/samples/naggypull.diff', (err, result) ->
        return done(err) if err
        Bot.apps.reviews.unidiff.parse result, (err, unidiff) ->
          return done(err) if err
          fs.readFile Bot.root + "/app/reviews/specs/samples/naggycomments.json", (err, content) ->
            return done(err)  if err
            Bot.db.reviews.thinkWhatYouSay unidiff, JSON.parse(content), (err, result) ->
              return done(err) if err
              diff = unidiff
              comments = result
              done()

    it "should create some comments", (done) ->
      should.exist comments
      comments.length.should.be.above 0
      done()

    it "should not comment files absent in the diff", (done) ->
      fakecomment = comments.find (comment) ->
        comment.file is "fake.js"
      should.not.exist fakecomment
      done()

    it "should comment files present in the diff", (done) ->
      worker = comments.find (comment) ->
        comment.file is "app/reviews/specs/unidiff_spec.coffee"
      should.exist worker
      done()

    it "should not comment lines not present in the diff", (done) ->
      workerComments = comments.findAll (comment) ->
        comment.file is "app/reviews/specs/unidiff_spec.coffee"
      oldIssue = workerComments.find (comment) ->
        comment.line is 15 or comment.line is 50
      should.not.exist oldIssue
      done()

    it "should not comment lines present in the diff, but not changed (added) there, i.e neutral ones", (done) ->
      workerComments = comments.findAll (comment) ->
        comment.file is "app/reviews/specs/unidiff_spec.coffee"
      neutral = workerComments.findAll (comment) ->
        [69].any comment.line
      neutral.should.eql []
      done()

    it "should comment lines present in the diff", (done) ->
      workerComments = comments.findAll (comment) ->
        comment.file is "app/reviews/specs/unidiff_spec.coffee"
      issues = workerComments.findAll (comment) ->
        [89, 90, 94, 95, 96].include comment.line
      should.exist issues
      issues.length.should.eql 5
      done()

    it "should provide diff index for commented lines", (done) ->
      workerComments = comments.findAll (comment) ->
        comment.file is "app/reviews/specs/unidiff_spec.coffee"
      workerComments.map("uniline").should.eql [39, 40, 44, 45, 46]
      done()

  describe 'push', ->
    [review, github] = [null, null]
    beforeEach (done) ->
      github = global.GitHub
      global.GitHub = ->
      global.GitHub.prototype.pullRequests ||= {}
      global.GitHub.prototype.pullRequests.createComment = (comment, next) -> next()
      Bot.db.reviews.save {
        github:
          token: '321'
          user: 'monkey'
          pull_request:
            number: 2
            head:
              sha: 'abc'
              repo:
                name: 'monkeytest'
                owner:
                  login: 'monkey'
        analyze:
          report:
            comments: [
              {
                message: "Line exceeds maximum allowed length",
                description: "This rule imposes a maximum line length on your code. <a\nhref=\"http://www.python.org/dev/peps/pep-0008/\">Python's style\nguide</a> does a good job explaining why you might want to limit the\nlength of your lines, though this is a matter of taste.\n\nLines can be no longer than eighty characters by default.",
                context: "Length is 120, max is 80",
                line: 89,
                uniline: 39,
                file: "app/reviews/specs/unidiff_spec.coffee",
                lineText: {
                  action: "+",
                  text: "            pack.ranges.first().lines.map('action').should.eql [null, null, null, null, '-', '+', '+', null, null, null]",
                  uniline: 39
                }
              },
              {
                message: "Line exceeds maximum allowed length",
                description: "This rule imposes a maximum line length on your code. <a\nhref=\"http://www.python.org/dev/peps/pep-0008/\">Python's style\nguide</a> does a good job explaining why you might want to limit the\nlength of your lines, though this is a matter of taste.\n\nLines can be no longer than eighty characters by default.",
                context: "Length is 118, max is 80",
                line: 90,
                uniline: 40,
                file: "app/reviews/specs/unidiff_spec.coffee",
                lineText: {
                  action: "+",
                  text: "            worker.ranges[1].lines.map('action').should.eql [null, null, null, null, '+', '+', null, null, null, null]",
                  uniline: 40
                }
              }
            
            ]
      }, (err, result) ->
        return done(err) if err
        review = result
        done()

    afterEach (done) ->
      global.GitHub = github
      done()

    it "should authenticate to github", (done) ->
      global.GitHub.prototype.pullRequests.createComment = (comment, next) -> next()
      global.GitHub.prototype.authenticate = (args) ->
        args.type.should.eql 'oauth'
        args.token.should.eql '321'
        done()
      Bot.db.reviews.push review, (err) ->

    it "should post comments to GitHub", (done) ->
      times = 0
      GitHub.prototype.authenticate = (args) ->
      GitHub.prototype.pullRequests = { }
      GitHub.prototype.pullRequests.createComment = (comment, next) ->
        comment.user.should.eql 'monkey'
        comment.repo.should.eql 'monkeytest'
        comment.number.should.eql 2
        comment.commit_id.should.eql 'abc'
        comment.body.should.eql "Line exceeds maximum allowed length"
        comment.path.should.eql "app/reviews/specs/unidiff_spec.coffee"
        should.exist [39, 40].find(comment.position)
        times += 1
        next null, {}

      Bot.db.reviews.push review, (err) ->
        times.should.eql 2
        done()

