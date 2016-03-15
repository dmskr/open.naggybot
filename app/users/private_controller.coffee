module.exports = (Bot, done) ->
  exports = {}
  exports.current = (req, res, next) ->
    next()

  exports.update = (req, res, next) ->
    next()

  exports.index = (req, res, next) ->
    next()

  done(null, exports)
