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

global.Skin = express()
Skin.root = __dirname
Skin.settings.port = 8081

global.server = require('http').createServer(Skin)
global.isServer = true

# Setup SMTP
Skin.settings.email = {
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

global.smtp = nodemailer.createTransport("SMTP", Skin.settings.email.auth)

# Cache timestamps
Skin.locals.tsjs = Skin.locals.tscss = Date.create().getTime()

# Environment
require("./config/environment")

# Applications
require("./config/applications")

# Run the server
env = (process.env.NODE_ENV || 'development').capitalize()
server.listen(Skin.settings.port)
console.log("Http server listening on http://0.0.0.0:8081")
console.log("Node Skin server started in #{env} environment")

