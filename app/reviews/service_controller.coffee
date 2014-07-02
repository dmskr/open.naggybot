exports.create = (req, res, next) ->
  return res.json status: 'ok' if req.headers['x-github-event'] == 'ping'
  return next() if ['pull_request'].indexOf(req.headers['x-github-event']) == -1

  Bot.db.reviews.save { github: JSON.parse((req.body || {}).payload) }, (err, review) ->
    return next(err) if err
    res.json status: 'ok'

