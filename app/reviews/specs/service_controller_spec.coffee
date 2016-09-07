fs = require "fs"
async = require "async"

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

    describe "result", ->
      result = null
      beforeEach (done) ->
        res.json = ->
          Bot.db.reviews.find().limit(1).toArray (err, reviews)->
            return done(err) if err
            result = reviews && reviews.first()
            done()

        Bot.apps.reviews.controller.service.create req, res, next


      it "should exist in database", ->
        should.exist result

      it "should have everything received into the github property", ->
        should.exist result.github
        should.exist Object.select(result.github, 'action', 'number').should.eql {
          action: 'synchronize'
          number: 3
        }

      it "should copy title to the root review object", ->
        should.exist result.title
        result.title.should.eql "UniDiff parsing refactored a bit"

      it "should copy username to the root review object", ->
        should.exist result.username
        result.username.should.eql "dmskr"

      it "should copy github id to review's refid", ->
        should.exist result.refid
        result.refid.should.eql "16423422"

      it "should copy github link to the PR", ->
        should.exist result.url
        result.url.should.eql "https://api.github.com/repos/dmskr/naggybot/pulls/3"

