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

[database, host, port] = if app.settings.env == 'production'
  ['naggybot', '95.85.16.168', 8081]
else if app.settings.env == 'test'
  ['naggybot_test', 'localhost:8082', 8082]
else
  ['naggybot_dev', 'localhost:8081', 8081]

mongourl = "mongodb://localhost:27017/#{database}?auto_reconnect=true"
app.db = mongo.db(mongourl, safe: true)

github = if app.settings.env == 'production'
  client_id: "6fad070068889058d583"
  secret: "e174e890fcfa46f6ce24781635fa601522724d9d"
else
  client_id: "76f9ddbeb73de6823fab"
  secret: "4850ec99a910c8f1a4d654880adebc84dbc243af"

app.set 'github', github
app.set 'host', host
app.set 'port', port
app.use serveStatic("static")
app.set 'views', app.root + "/app"
app.set 'view options', { layout: false }
app.use bodyParser()
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
  key: 'naggybot.sid'
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

app.use(morgan(format: 'dev'))
app.use(passport.initialize())
app.use(passport.session())

