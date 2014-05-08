global.express = require('express')
global.connect = require('connect')
global.sugar = require("sugar")
global.mongo = require('mongoskin')
global.fs = require('fs')
global.passport = require('passport')
global.LocalStrategy = require('passport-local').Strategy
global.bcrypt = require('bcrypt')
global.crypto = require('crypto')
global.querystring = require('querystring')
global.exec = require('child_process').exec
global.nodemailer = require('nodemailer')
global.URI = require('url')
global.Path = require('path')
global.async = require('async')

global.App = express()
App.root = __dirname
App.settings.port = 8081

global.server = require('http').createServer(App)
global.isServer = true

# Setup SMTP
App.settings.email = {
  auth: {
    host: "",
    secureConnection: false,
    port: 111,
    auth: {
      user: "",
      pass: ""
    }
  }
}

global.smtp = nodemailer.createTransport("SMTP", App.settings.email.auth)

# Cache timestamps
App.locals.tsjs = App.locals.tscss = Date.create().getTime()

# Run the server
env = (process.env.NODE_ENV || 'development').capitalize()
server.listen(App.settings.port)
console.log("Http server listening on http://0.0.0.0:8081")
console.log("App server started in #{env} environment")

