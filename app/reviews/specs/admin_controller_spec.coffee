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
        params.data.each (task, index) ->
          params.data[index + 1] and task.createdAt.should.be.above(params.data[index + 1].createdAt)
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
        params.data.each (task, index) ->
          params.data[index + 1] and task.createdAt.should.be.above(params.data[index + 1].createdAt)

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
        params.data.each (task, index) ->
          params.data[index + 1] and task.createdAt.should.be.above(params.data[index + 1].createdAt)
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
        params.data.each (task, index) ->
          params.data[index + 1] and task.createdAt.should.be.above(params.data[index + 1].createdAt)

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
        params.data.each (task, index) ->
          params.data[index + 1] and task.createdAt.should.be.above(params.data[index + 1].createdAt)

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
    task = null
    beforeEach (done) ->
      Bot.db.reviews.save
        type: "some"
      , (err, t) ->
        return done(err)  if err
        task = t
        done()

    it "should render correct template", (done) ->
      req.params.id = task._id
      res.render = (template, params) ->
        template.should.eql Bot.root + "/app/reviews/admin/show.jade"
        should.exist params.task
        params.task._id.should.eql task._id
        done()

      Bot.apps.reviews.controller.admin.show req, res, next

