module.exports = (Bot, initDone)->
  mongo = require("mongodb").MongoClient
  session = require('express-session')
  MongoStore = require('connect-mongo')(session)
  cookieParser = require('cookie-parser')
  bodyParser = require('body-parser')
  flash = require('connect-flash')
  serveStatic = require('serve-static')
  poweredBy = require('connect-powered-by')
  morgan  = require('morgan')
  methodOverride = require('method-override')
  passport = require('passport')

  app = Bot.express

  #Logger = require('mongodb').Logger
  #Logger.setLevel('debug')

  mongo.connect process.env.MONGODB, (err, db) ->
    return initDone(err) if err
    Bot.db = db

    app.set 'github',
      client_id: process.env.GITHUB_CLIENT
      secret: process.env.GITHUB_SECRET

    app.set 'host', process.env.EXT_HOST
    app.set 'port', process.env.INT_PORT
    app.use serveStatic("static")
    app.set 'views', app.root + "/app"
    app.set 'view options', { layout: false }

    app.use(bodyParser.urlencoded(extended: true))
    app.use(bodyParser.json())
    app.use cookieParser()
    app.use methodOverride()

    app.use(session(
      cookie:
        secure: false
        maxAge: 86400000000
        expires: (1).yearFromNow()
        httpOnly: false
      store: new MongoStore({ db: Bot.db })
      secret: "*vr6ylm(4bjeq^xuay@u(q0%@5hevcf=d1-prij_qu2_mg&r1q"
      key: 'naggybot.sid',
      resave: true,
      saveUninitialized: true
    ))

    app.use(flash())
    app.use(poweredBy(null))

    # Set flash messages
    app.use (req, res, next) ->
      original = res.render
      res.render = (template, options, callback) ->
        opts = Object.merge(options || {}, { flash: req.flash() })
        original.call res, template, opts, callback
      next()

    app.use(morgan('dev'))
    app.use(passport.initialize())
    app.use(passport.session())
    initDone()

