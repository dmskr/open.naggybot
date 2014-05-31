exports.create = (req, res, next) ->
  return res.json status: 'ok' if req.headers['X-GitHub-Event'] == 'ping'
  return next() if ['pull_request', 'PullRequestEvent'].indexOf(req.headers['X-GitHub-Event']) == -1

  Bot.db.reviews.save { github: req.body }, (err, review) ->
    return next(err) if err
    res.json status: 'ok'

