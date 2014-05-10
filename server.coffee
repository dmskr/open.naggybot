global.express = require('express')
global.connect = require('connect')
global.sugar = require("sugar")
global.mongo = require('mongoskin')
global.fs = require('fs')
global.passport = require('passport')
global.LocalStrategy = require('passport-local').Strategy
global.GitHubStrategy = require('passport-github').Strategy
global.bcrypt = require('bcrypt')
global.crypto = require('crypto')
global.querystring = require('querystring')
global.exec = require('child_process').exec
global.nodemailer = require('nodemailer')
global.URI = require('url')
global.Path = require('path')
global.async = require('async')
global.GitHub = require('github')

global.Bot = express()
Bot.root = __dirname
Bot.settings.port = 8081

global.server = require('http').createServer(Bot)
global.isServer = true

# Setup SMTP
Bot.settings.email = {
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

global.smtp = nodemailer.createTransport("SMTP", Bot.settings.email.auth)

# Cache timestamps
Bot.locals.tsjs = Bot.locals.tscss = Date.create().getTime()

# Environment
require("./config/environment")

# Applications
require("./config/applications")

# Run the server
env = (process.env.NODE_ENV || 'development').capitalize()
server.listen(Bot.settings.port)
console.log("Http server listening on http://0.0.0.0:8081")
console.log("NaggyBot App server started in #{env} environment")

