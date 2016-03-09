async = require("async")
pathUtil = require "path"

module.exports = (Bot, done) ->
  exports = {}
  exports.lint = (files, done) ->
    report = comments: []
    async.eachSeries files, (file, next) ->
      exports.coffee file, (err, result) ->
        return next(err) if err
        comments = Object.values(result).flatten()
        comments.each (comment) ->
          comment.file = file if comment
          comment.line = comment.lineNumber
          delete comment.lineNumber
        report.comments = report.comments.concat(comments)
        next()
    , (err) ->
      return done(err) if err
      done null, report

  exports.coffee = (path, done) ->
    return done() if pathUtil.extname(path) != '.coffee'
    exec "nice ./node_modules/coffeelint/bin/coffeelint --reporter raw #{path}", (err, content) ->
      # Just ignore any errors as any output is treated as an error here, including json report
      # return done(err) if err
      return done(null, {}) if content == ''
      result = null
      try
        result = JSON.parse(content)
      catch e
        return done(e)
      done(null, result)

  return done(null, exports)
