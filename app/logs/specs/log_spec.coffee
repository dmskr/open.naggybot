require "../../shared/specs/helpers"

describe "Log", ->
  describe 'skin save', ->
    shouldHaveCreatedAt('logs')
    shouldHaveUpdatedAt('logs')

    it "should append entities array if not specified", ->
      Bot.db.logs.save({}).then (log) ->
        should.exist log.entries
        log.entries.length.should.eql 0

    it "should ignore entries array if exist", ->
      Bot.db.logs.save({ entries: [{ text: 'Hello', createdAt: Date.create() }] }).then (log) ->
        should.exist log.entries
        log.entries.length.should.eql 1
        log.entries.first().text.should.eql 'Hello'

  describe 'write', ->
    it "return an error if no logId provided", ->
      Bot.db.logs.write({}, 'Something happens here').catch (err) ->
        err.should.eql new Error('No logId found')

    it "should append to existing log entries if logId is present", ->
      Bot.db.logs.save({ entries: [{ text: 'some', createdAt: Date.create() }]}).then (log) ->
        Bot.db.logs.write({ logId: log._id }, 'Brum-bum-bum').then ->
          Bot.db.logs.findById(log._id).then (log) ->
            log.entries.length.should.eql 2
            log.entries.last().text.should.eql 'Brum-bum-bum'
            should.exist log.entries.last().createdAt

