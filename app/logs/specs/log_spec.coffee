require "../../shared/specs/helpers"

describe "Log", ->
  describe 'skin save', ->
    shouldHaveCreatedAt('logs')
    shouldHaveUpdatedAt('logs')

    it "should append entities array if not specified", (done) ->
      Bot.db.logs.save {}, (err, log) ->
        return done(err) if err
        should.exist log.entries
        log.entries.length.should.eql 0
        done()

    it "should ignore entries array if exist", (done) ->
      Bot.db.logs.save { entries: [{ text: 'Hello', createdAt: Date.create() }] }, (err, log) ->
        return done(err) if err
        should.exist log.entries
        log.entries.length.should.eql 1
        log.entries.first().text.should.eql 'Hello'
        done()

  describe 'write', ->
    it "return an error if no logId provided", (done) ->
      Bot.db.logs.write {}, 'Something happens here', (err) ->
        should.exist err
        err.should.eql 'No logId found'
        done()

    it "should append to existing log entries if logId is present", (done) ->
      Bot.db.logs.save { entries: [{ text: 'some', createdAt: Date.create() }]}, (err, log) ->
        return done(err) if err
        Bot.db.logs.write { logId: log._id }, 'Brum-bum-bum', (err) ->
          return done(err) if err
          Bot.db.logs.findById log._id, (err, log) ->
            return done(err) if err
            log.entries.length.should.eql 2
            log.entries.last().text.should.eql 'Brum-bum-bum'
            should.exist log.entries.last().createdAt
            done()

