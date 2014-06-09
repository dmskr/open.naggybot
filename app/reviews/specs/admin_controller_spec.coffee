require "../../shared/specs/helpers"

describe "Reviews Admin Controller", ->
  describe "index", ->
    testPagingFor collection: "reviews"
    action = "index"

    it "should render proper view", (done) ->
      res.render = (template, options) ->
        template.should.eql Bot.root + "/app/reviews/admin/index.jade"
        done()

      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should not fail if no reviews found", (done) ->
      Bot.db.reviews.remove (err) ->
        return done(err)  if err
        res.render = (template, params) ->
          params.total.should.eql 0
          params.data.length.should.eql 0
          done()

        Bot.apps.reviews.controller.admin[action] req, res, next

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (review, index) ->
          params.data[index + 1] and review.createdAt.should.be.above(params.data[index + 1].createdAt)
        done()

      Bot.apps.reviews.controller.admin.index req, res, next

    it "should return correct tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql "all"
        done()
      Bot.apps.reviews.controller.admin.index req, res, next

  describe "active", ->
    testPagingFor
      collection: "reviews"
      action: "active"

    action = "active"
    beforeEach (done) ->
      Bot.db.reviews.update {},
        $set:
          status: "inprogress"
      ,
        multi: true
      , (err) ->
        done()

    it "should render proper view", (done) ->
      res.render = (template, options) ->
        template.should.eql Bot.root + "/app/reviews/admin/index.jade"
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should not fail if no reviews found", (done) ->
      Bot.db.reviews.remove (err) ->
        return done(err)  if err
        res.render = (template, params) ->
          params.total.should.eql 0
          params.data.length.should.eql 0
          done()
        Bot.apps.reviews.controller.admin[action] req, res, next

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (review, index) ->
          params.data[index + 1] and review.createdAt.should.be.above(params.data[index + 1].createdAt)

        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should return correct tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql "active"
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should only render reviews in inprogress status", (done) ->
      Bot.db.reviews.update {},
        $set:
          status: "pending"
      ,
        multi: true
      , (err) ->
        return done(err)  if err
        Bot.db.reviews.update
          title: 51
        ,
          $set:
            status: "inprogress"
        ,
          multi: true
        , (err) ->
          return done(err)  if err
          res.render = (template, params) ->
            params.data.length.should.eql 1
            params.data.first().title.should.eql 51
            done()
          Bot.apps.reviews.controller.admin[action] req, res, next

  describe "error", ->
    testPagingFor
      collection: "reviews"
      action: "error"

    action = "error"
    beforeEach (done) ->
      Bot.db.reviews.update {},
        $set:
          status: "error"
      ,
        multi: true
      , (err) ->
        done()

    it "should render proper view", (done) ->
      res.render = (template, options) ->
        template.should.eql Bot.root + "/app/reviews/admin/index.jade"
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should not fail if no reviews found", (done) ->
      Bot.db.reviews.remove (err) ->
        return done(err)  if err
        res.render = (template, params) ->
          params.total.should.eql 0
          params.data.length.should.eql 0
          done()
        Bot.apps.reviews.controller.admin[action] req, res, next

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (review, index) ->
          params.data[index + 1] and review.createdAt.should.be.above(params.data[index + 1].createdAt)
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should return correct tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql "error"
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should only render reviews in error status", (done) ->
      Bot.db.reviews.update {},
        $set:
          status: "pending"
      ,
        multi: true
      , (err) ->
        return done(err)  if err
        Bot.db.reviews.update
          title: 51
        ,
          $set:
            status: "error"
        ,
          multi: true
        , (err) ->
          return done(err)  if err
          res.render = (template, params) ->
            params.data.length.should.eql 1
            params.data.first().title.should.eql 51
            done()
          Bot.apps.reviews.controller.admin[action] req, res, next

  describe "completed", ->
    testPagingFor
      collection: "reviews"
      action: "completed"

    action = "completed"
    beforeEach (done) ->
      Bot.db.reviews.update {},
        $set:
          status: "completed"
      ,
        multi: true
      , (err) ->
        done()

    it "should render proper view", (done) ->
      res.render = (template, options) ->
        template.should.eql Bot.root + "/app/reviews/admin/index.jade"
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should not fail if no reviews found", (done) ->
      Bot.db.reviews.remove (err) ->
        return done(err)  if err
        res.render = (template, params) ->
          params.total.should.eql 0
          params.data.length.should.eql 0
          done()
        Bot.apps.reviews.controller.admin[action] req, res, next

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (review, index) ->
          params.data[index + 1] and review.createdAt.should.be.above(params.data[index + 1].createdAt)

        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should return correct tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql "completed"
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should only render reviews in completed status", (done) ->
      Bot.db.reviews.update {},
        $set:
          status: "pending"
      ,
        multi: true
      , (err) ->
        return done(err)  if err
        Bot.db.reviews.update
          title: 51
        ,
          $set:
            status: "completed"
        ,
          multi: true
        , (err) ->
          return done(err)  if err
          res.render = (template, params) ->
            params.data.length.should.eql 1
            params.data.first().title.should.eql 51
            done()
          Bot.apps.reviews.controller.admin[action] req, res, next

  describe "pending", ->
    testPagingFor
      collection: "reviews"
      action: "pending"

    action = "pending"
    beforeEach (done) ->
      Bot.db.reviews.update {},
        $set:
          status: "pending"
      ,
        multi: true
      , (err) ->
        done()

    it "should render proper view", (done) ->
      res.render = (template, options) ->
        template.should.eql Bot.root + "/app/reviews/admin/index.jade"
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should not fail if no reviews found", (done) ->
      Bot.db.reviews.remove (err) ->
        return done(err)  if err
        res.render = (template, params) ->
          params.total.should.eql 0
          params.data.length.should.eql 0
          done()
        Bot.apps.reviews.controller.admin[action] req, res, next

    it "should show recent first", (done) ->
      res.render = (view, params) ->
        params.data.each (review, index) ->
          params.data[index + 1] and review.createdAt.should.be.above(params.data[index + 1].createdAt)

        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should return correct tab name", (done) ->
      res.render = (template, params) ->
        params.tab.should.eql "pending"
        done()
      Bot.apps.reviews.controller.admin[action] req, res, next

    it "should only render reviews in pending status", (done) ->
      Bot.db.reviews.update {},
        $set:
          status: "completed"
      ,
        multi: true
      , (err) ->
        return done(err)  if err
        Bot.db.reviews.update
          title: 51
        ,
          $set:
            status: "pending"
        ,
          multi: true
        , (err) ->
          return done(err)  if err
          res.render = (template, params) ->
            params.data.length.should.eql 1
            params.data.first().title.should.eql 51
            done()
          Bot.apps.reviews.controller.admin[action] req, res, next


  describe "show", ->
    review = null
    beforeEach (done) ->
      Bot.db.reviews.save
        type: "some"
      , (err, t) ->
        return done(err)  if err
        review = t
        done()

    it "should render correct template", (done) ->
      req.params.id = review._id
      res.render = (template, params) ->
        template.should.eql Bot.root + "/app/reviews/admin/show.jade"
        should.exist params.review
        params.review._id.should.eql review._id
        done()

      Bot.apps.reviews.controller.admin.show req, res, next

    it "should return 'next' action with no error if review is not found", (done) ->
      req.params.id = review._id + 'not_existing'
      Bot.apps.reviews.controller.admin.show req, res, (err) ->
        should.not.exist err
        done()

  describe 'pull', ->
    review = null
    beforeEach (done) ->
      nonmock.replace Bot.db.reviews, 'pull', (rev, callback) -> callback(null, rev)
      Bot.db.reviews.save { github: {} }, (err, result) ->
        return done(err) if err
        review = result
        req.params.id = review._id
        done()

    it "should run review pulling", (done) ->
      nonmock.replace Bot.db.reviews, 'pull', (pullthis, callback) ->
        should.exist pullthis
        pullthis._id.should.eql review._id
        done()

      Bot.apps.reviews.controller.admin.pull req, res, next

    it "should redirect to review#show url", (done) ->
      res.redirect = (url) ->
        url.should.eql '/admin/reviews/' + review._id
        done()
      Bot.apps.reviews.controller.admin.pull req, res, next

  describe 'analyze', ->
    review = null
    beforeEach (done) ->
      nonmock.replace Bot.db.reviews, 'analyze', (rev, callback) -> callback(null, rev)
      Bot.db.reviews.save { github: {} }, (err, result) ->
        return done(err) if err
        review = result
        req.params.id = review._id
        done()

    it "should run review analyzing", (done) ->
      nonmock.replace Bot.db.reviews, 'analyze', (analyze, callback) ->
        should.exist analyze
        analyze._id.should.eql review._id
        done()

      Bot.apps.reviews.controller.admin.analyze req, res, next

    it "should redirect to review#show url", (done) ->
      res.redirect = (url) ->
        url.should.eql '/admin/reviews/' + review._id
        done()
      Bot.apps.reviews.controller.admin.analyze req, res, next

  describe 'push', ->
    review = null
    beforeEach (done) ->
      nonmock.replace Bot.db.reviews, 'push', (rev, callback) -> callback(null, rev)
      Bot.db.reviews.save { github: {} }, (err, result) ->
        return done(err) if err
        review = result
        req.params.id = review._id
        done()

    it "should run review analyzing", (done) ->
      nonmock.replace Bot.db.reviews, 'push', (push, callback) ->
        should.exist push
        push._id.should.eql review._id
        done()

      Bot.apps.reviews.controller.admin.push req, res, next

    it "should redirect to review#show url", (done) ->
      res.redirect = (url) ->
        url.should.eql '/admin/reviews/' + review._id
        done()
      Bot.apps.reviews.controller.admin.push req, res, next
