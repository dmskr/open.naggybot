require "../../shared/specs/helpers"

describe "Adviser", ->
  describe 'lint', ->
    [coffee, exec] = [null, null]
    beforeEach (done) ->
      coffee = Bot.apps.reviews.adviser.coffee
      exec = global.exec
      global.exec = (command, callback) -> callback null, command
      done()

    afterEach (done) ->
      Bot.apps.reviews.adviser.coffeelint = coffee
      global.exec = exec
      done()

    it "should return no errors if no files were provided", (done) ->
      Bot.apps.reviews.adviser.lint [], (err, report) ->
        return done(err) if err
        should.exist report
        report.should.eql {}
        done()

    it "should send to coffeelint all coffee files", (done) ->
      files = [
        'path/to/some.coffee'
        'path/to/another.coffee'
        'path/to/some.json'
        'path/to/some.diff'
        'path/to/again.coffee'
      ]
      global.exec = (command, callback) ->
        command.should.match /^\.\/node_modules\/coffeelint\/bin\/coffeelint --reporter raw/
        callback null, JSON.stringify({ command: command })

      Bot.apps.reviews.adviser.lint files, (err, report) ->
        return done(err) if err
        Object.keys(report).should.eql ['path/to/some.coffee', 'path/to/another.coffee', 'path/to/again.coffee']
        done()

