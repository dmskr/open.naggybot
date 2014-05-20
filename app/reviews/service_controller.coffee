exports.create = (req, res, next) ->
  return next() if ['pull_request', 'PullRequestEvent'].indexOf(req.headers['X-GitHub-Event']) == -1

  Bot.db.reviews.save { pull_request: req.body.pull_request }, (err, review) ->
    return next(err) if err
    res.json status: 'ok'

