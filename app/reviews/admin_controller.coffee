pageSize = 100
exports.index = (req, res, next) ->
  req.locals =
    cursor: Bot.db.reviews.find({}).sort(createdAt: -1)
    tab: "all"

  exports.renderHtml req, res, next

exports.active = (req, res, next) ->
  req.locals =
    cursor: Bot.db.reviews.find(status: "inprogress").sort(createdAt: -1)
    tab: "active"

  exports.renderHtml req, res, next
  return

exports.completed = (req, res, next) ->
  req.locals =
    cursor: Bot.db.reviews.find(status: "completed").sort(createdAt: -1)
    tab: "completed"

  exports.renderHtml req, res, next

exports.error = (req, res, next) ->
  req.locals =
    cursor: Bot.db.reviews.find(status: "error").sort(createdAt: -1)
    tab: "error"

  exports.renderHtml req, res, next

exports.pending = (req, res, next) ->
  req.locals = {
    cursor: Bot.db.reviews.find({ status: 'pending' }).sort({
      createdAt: -1
    }),
    tab: 'pending'
  }
  exports.renderHtml req, res, next

exports.renderHtml = (req, res, next) ->
  page = ((req.query || {}).page || 0).toNumber()

  async.parallel {
    data: (done) -> req.locals.cursor.skip(page * pageSize).limit(pageSize).toArray(done)
    total: (done) -> req.locals.cursor.count(done)
  }, (err, results) ->
    return next(err) if (err)
    res.render Bot.root + '/app/reviews/admin/index.jade', Object.merge(results, {
      page: page,
      tab: req.locals.tab || 'all'
    })

exports.show = (req, res, next) ->
  Bot.db.reviews.findById req.params.id, (err, review) ->
    return next(err)  if err
    res.render Bot.root + "/app/reviews/admin/show.jade",
      review: review
