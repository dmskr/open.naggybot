exports.create = (req, res, next) ->
  return next() if ['pull_request', 'PullRequestEvent'].indexOf(req.headers['X-GitHub-Event']) == -1

  Bot.db.reviews.save { pull_request: req.body.pull_request }, (err, review) ->
    return next(err) if err
    res.json status: 'ok'

exports.execute = (req, res, next) ->
  res.json status: 'ok'

exports.expire = (req, res, next) ->
  Bot.db.reviews.find(
    status: "inprogress"
    createdAt:
      $lt: (10).minutesAgo()
  ).toArray (err, reviews) ->
    return next(err)  if err
    async.each reviews or [], ((review, callback) ->
      review.status = "expired"
      Bot.db.reviews.save review, callback
    ), (err) ->
      return next(err)  if err
      res.json "200",
        expired: reviews.length

