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

  #describe "expire", ->
    #it "should expire any task created more than 10 minutes ago in not completed status still", (done) ->
      #Bot.db.reviews.save
        #status: "inprogress"
        #createdAt: (11).minutesAgo()
      #, (err, task) ->
        #res.json = (st, data) ->
          #Bot.db.reviews.findById task._id, (err, task) ->
            #task.status.should.eql "expired"
            #done()
        #Bot.apps.reviews.controller.admin.expire req, res, next

    #it "should ignore all completed reviews", (done) ->
      #Bot.db.reviews.save
        #status: "completed"
        #createdAt: (11).minutesAgo()
      #, (err, task) ->
        #res.json = (st, data) ->
          #Bot.db.reviews.findById task._id, (err, task) ->
            #task.status.should.eql "completed"
            #done()
        #Bot.apps.reviews.controller.admin.expire req, res, next

    #it "should ignore all non completed reviews created less than 10 minutes ago", (done) ->
      #Bot.db.reviews.save
        #status: "inprogress"
        #createdAt: (9).minutesAgo()
      #, (err, task) ->
        #res.json = (st, data) ->
          #Bot.db.reviews.findById task._id, (err, task) ->
            #task.status.should.eql "inprogress"
            #done()
        #Bot.apps.reviews.controller.admin.expire req, res, next

  #describe "execute", ->
    #download = null
    #execute = null
    #thumbnail = null
    #beforeEach (done) ->
      #download = Bot.db.images.download
      #execute = Bot.db.images.execute
      #thumbnail = Bot.db.images.thumbnail
      #async.each [
        #{
          #type: "convert"
          #url: "http://convert"
        #}
        #{
          #type: "thumbnail"
          #url: "http://thumbnail"
          #path: "/thumbnail"
        #}
        #{
          #type: "thumbnail"
          #url: "http://thumbnail"
          #status: "pending"
          #path: "/thumbnail"
        #}
        #{
          #type: "thumbnail"
          #status: "error"
        #}
        #{
          #type: "thumbnail"
          #status: "inprogress"
        #}
        #{
          #type: "thumbnail"
          #status: "completed"
        #}
      #], ((task, callback) ->
        #Bot.db.reviews.save task, callback
      #), done

    #afterEach (done) ->
      #Bot.db.images.download = download
      #Bot.db.images.execute = execute
      #Bot.db.images.thumbnail = thumbnail
      #done()

    #it "should send to download all thumbnail reviews in empty or pending status", (done) ->
      #times = 0
      #res.send = ->
        #times.should.eql 2
        #done()

      #Bot.db.images.thumbnail = (path, callback) ->
        #callback null,
          #tile250: "some"
      #Bot.db.images.download = (options, callback) ->
        #options.url.should.eql "http://thumbnail"
        #times = times + 1
        #callback()

      #Bot.apps.reviews.controller.admin.execute req, res, next

    #it "should send to images.thumbnail all downloaded images", (done) ->
      #times = 0
      #res.send = ->
        #times.should.eql 2
        #done()

      #Bot.db.images.thumbnail = (path, callback) ->
        #path.should.eql "/thumbnail"
        #times = times + 1
        #callback null,
          #tile250: "some"

      #Bot.db.images.download = (options, callback) ->
        #callback null

      #Bot.apps.reviews.controller.admin.execute req, res, next

    #it "should save task as completed with thumbnail path provided", (done) ->
      #Bot.db.images.thumbnail = (path, callback) ->
        #callback null,
          #tile250: "some"

      #Bot.db.images.download = (options, callback) ->
        #callback null, "/some"

      #res.send = ->
        #Bot.db.reviews.find(
          #type: "thumbnail"
          #status: "completed"
        #).toArray (err, reviews) ->
          #sh.not.exist err
          #sh.exist reviews
          #reviews.length.should.eql 3
          #done()

      #Bot.apps.reviews.controller.admin.execute req, res, next
