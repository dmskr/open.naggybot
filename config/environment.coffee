skinstore = require('connect-mongoskin')
cookieParser = require('cookie-parser')
session = require('express-session')
bodyParser = require('body-parser')
flash = require('connect-flash')
serveStatic = require('serve-static')
poweredBy = require('connect-powered-by')
morgan  = require('morgan')
methodOverride = require('method-override')

app = Bot

[database, host, port, dbhost] = if app.settings.env == 'production'
  ['naggybot', '95.85.16.168', 8081, 'mongodb']
else if app.settings.env == 'test'
  ['naggybot_test', 'localhost:8082', 8082, 'localhost']
else
  ['naggybot_dev', 'localhost:8081', 8081, 'localhost']

mongourl = "mongodb://#{dbhost}:27017/#{database}?auto_reconnect=true"
app.db = mongo.db(mongourl, safe: true)

app.set 'github',
  client_id: process.env.GITHUB_CLIENT
  secret: process.env.GITHUB_SECRET

app.set 'host', host
app.set 'port', port
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
  store: new skinstore(app.db)
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

