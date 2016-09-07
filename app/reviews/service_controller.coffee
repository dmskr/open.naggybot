module.exports = (Bot, done) ->
  exports = {}
  exports.create = (req, res, next) ->
    return res.json status: 'ok' if req.headers['x-github-event'] == 'ping'
    return next() if ['pull_request'].indexOf(req.headers['x-github-event']) == -1

    payload = JSON.parse((req.body || {}).payload)
    review = {
      title: payload.pull_request.title,
      username: payload.pull_request.user.login,
      refid: payload.pull_request.id.toString()
      url: payload.pull_request.url,
      github: payload
    }

    Bot.db.reviews.save review, (err, review) ->
      return next(err) if err
      res.json status: 'ok'

  exports.work = (next) ->
  return done(null, exports)

