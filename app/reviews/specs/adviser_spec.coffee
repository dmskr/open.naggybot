require "../../shared/specs/helpers"

describe "Adviser", ->
  describe 'lint', ->
    [coffee, exec] = [null, null]
    beforeEach (done) ->
      coffee = Bot.apps.reviews.adviser.coffee
      exec = global.exec
      global.exec = (command, callback) -> callback null, JSON.stringify(filename: [command: command])
      done()

    afterEach (done) ->
      Bot.apps.reviews.adviser.coffeelint = coffee
      global.exec = exec
      done()

    it "should return no errors if no files were provided", (done) ->
      Bot.apps.reviews.adviser.lint [], (err, report) ->
        return done(err) if err
        should.exist report
        report.should.eql comments: []
        done()

    it "should restructure result to include file names inside each comment", (done) ->
      files = [ 'path/to/some.coffee' ]
      Bot.apps.reviews.adviser.lint files, (err, report) ->
        return done(err) if err
        report.comments.each (comment) ->
          (comment instanceof Array).should.eql false
          should.exist comment.file
          comment.file.should.eql 'path/to/some.coffee'
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
        callback null, JSON.stringify(filename: [command: command])

      Bot.apps.reviews.adviser.lint files, (err, report) ->
        return done(err) if err
        report.comments.map('file').should.eql ['path/to/some.coffee', 'path/to/another.coffee', 'path/to/again.coffee']
        done()

    it "should ignore any errors returned by exec as coffeelint returns json to the stdout", (done) ->
      files = [ 'path/to/some.coffee' ]
      global.exec = (command, callback) ->
        callback new Error('Blah-Blah'), JSON.stringify(filename: [command: command])
      Bot.apps.reviews.adviser.lint files, (err, report) ->
        return done(err) if err
        report.comments.map('file').should.eql ['path/to/some.coffee']
        done()

    it "should convert lineNumber to line", (done) ->
      files = [ 'path/to/some.coffee' ]
      global.exec = (command, callback) ->
        callback new Error('Blah-Blah'), JSON.stringify(filename: [{ command: command, lineNumber: 101 }])
      Bot.apps.reviews.adviser.lint files, (err, report) ->
        return done(err) if err
        should.exist report.comments.first().line
        report.comments.first().line.should.eql 101
        done()

