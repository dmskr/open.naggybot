crypto = require("crypto")
async = require("async")

module.exports = (Bot, done) ->
  exports = {}
  pageSize = 100
  exports.index = (req, res, next) ->
    req.locals =
      cursor: Bot.db.users.find({}).sort(createdAt: -1)
      tab: "all"

    if req.params.format is "csv"
      exports.renderCsv req, res, next
    else
      exports.renderHtml req, res, next

  exports.all = exports.index
  exports.blocked = (req, res, next) ->
    req.locals =
      cursor: Bot.db.users.find(access: false).sort(createdAt: -1)
      tab: "blocked"

    if req.params.format is "csv"
      exports.renderCsv req, res, next
    else
      exports.renderHtml req, res, next

  exports.active = (req, res, next) ->
    req.locals =
      cursor: Bot.db.users.find(
        access: true
        confirmedAt:
          $exists: true
          $ne: null

        password:
          $exists: true
          $ne: null
      ).sort(visitedAt: -1)
      tab: "active"

    if req.params.format is "csv"
      exports.renderCsv req, res, next
    else
      exports.renderHtml req, res, next

  exports.search = (req, res, next) ->
    Bot.db.keywords.toConditions req.query.term, (err, conditions) ->
      return next(err)  if err
      conditions ||= {}
      req.locals =
        cursor: Bot.db.users.find(conditions).sort(visitedAt: -1)
        tab: "search"
        term: req.query.term

      if req.params.format is "csv"
        exports.renderCsv req, res, next
      else
        exports.renderHtml req, res, next

  exports.renderHtml = (req, res, next) ->
    page = ((req.query or {}).page or 0).toNumber()
    async.parallel
      data: (done) ->
        req.locals.cursor.skip(page * pageSize).limit(pageSize).toArray done
      total: (done) ->
        req.locals.cursor.count done
    , (err, results) ->
      return next(err)  if err
      res.render Bot.root + "/app/users/admin/index.jade", Object.merge(results,
        page: page
        tab: req.locals.tab or "all"
        term: req.locals.term
      )

  exports.renderCsv = (req, res, next) ->
    csv = []
    header = [
      "_id"
      "email"
      "confirmedAt"
      "createdAt"
      "access"
      "admin"
      "greetingsSent"
      "initiatedAt"
      "resetedAt"
      "updatedAt"
      "visitedAt"
    ]
    csv.push header.join(",")
    user = null
    async.doWhilst ((next) ->
      req.locals.cursor.nextObject (err, u) ->
        return next(err)  if err
        user = u
        return next()  unless user
        line = header.map((h) ->
          if user[h] and user[h].constructor is Date
            user[h].format "{dd}/{MM}/{yyyy} {hh}:{mm}"
          else
            user[h]
        )
        csv.push line.join(",")
        process.nextTick next
    ), (->
      !!user
    ), (err) ->
      return next(err)  if err
      res.setHeader "Content-Type", "text/csv"
      res.setHeader "Content-Disposition", "attachment; filename=users.csv"
      res.send csv.join("\n")

  exports.export = (req, res, next) ->
    req.locals = cursor: Bot.db.users.find().sort(createdAt: -1)
    exports.renderCsv req, res, next

  exports.show = (req, res, next) ->
    Bot.db.users.findById req.params.id, (err, user) ->
      return next(err)  if err
      try
        user.emailmd5 = crypto.createHash("md5").update((user and user.email) or "").digest("hex").toString()
        res.render Bot.root + "/app/users/admin/form.jade",
          man: user
      catch err
        next err

  exports.update = (req, res, next) ->
    Bot.db.users.findById req.params.id, (err, user) ->
      return next(err) if err
      user.email = req.body.user.email
      user.username = req.body.user.username
      user.password = req.body.user.password if req.body.user.password
      user.access = !!req.body.user.access
      Bot.db.users.save user, (err) ->
        res.redirect "/admin/users"

  exports.autocomplete = (req, res, next) ->
    Bot.db.users.autocomplete req.params.term or req.query.term, (err, users) ->
      return next(err) if err
      res.json "200",
        users: users

  done(null, exports)
