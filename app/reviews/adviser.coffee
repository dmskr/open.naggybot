
exports.lint = (files, done) ->
  report = {}
  async.each files, (file, next) ->
    exports.coffee file, (err, result) ->
      return next(err) if err
      if result
        report[file] = result
      next()
  , (err) ->
    return done(err) if err
    done null, report

exports.coffee = (path, done) ->
  return done() if pathUtil.extname(path) != '.coffee'
  exec "./node_modules/coffeelint/bin/coffeelint --reporter raw #{path}", (err, content) ->
    return done(err) if err
    result = null
    try
      result = JSON.parse(content)
    catch e
      return done(e)
    done(null, result)


