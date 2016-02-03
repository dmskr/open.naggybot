Bot = exports.Bot = {}

Bot.dotenv = require('dotenv')
Bot.dotenv.load()

Bot.express = require('express')()
Bot.sugar = require("sugar")
Bot.mongo = require('mongodb').MongoClient
Bot.bcrypt = require('bcrypt')
Bot.crypto = require('crypto')
Bot.querystring = require('querystring')
Bot.exec = require('child_process').exec
Bot.nodemailer = require('nodemailer')
Bot.URI = require('url')
Bot.Path = require('path')
Bot.async = require('async')
Bot.GitHub = require('github')
Bot.request = require('request')
Bot.tmp = require 'tmp'
Bot.tar = require 'tar'
Bot.fstream = require 'fstream'
Bot.pathUtil = require 'path'
Bot.os = require 'os'

Bot.root = __dirname

Bot.server = require('http').createServer(Bot.express)
Bot.isServer = true

# Setup SMTP
Bot.express.settings.email = {
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

Bot.smtp = Bot.nodemailer.createTransport("SMTP", Bot.express.settings.email.auth)

# Cache timestamps
Bot.express.locals.tsjs = Bot.express.locals.tscss = Date.create().getTime()

# Environment
require("./config/environment") Bot, ->
  # Applications
  require("./config/applications") Bot, ->
    ## Nodetime
    #if process.env.NODE_ENV == 'production'
      #require('nodetime').profile {
        #accountKey: '99fb39f6d50c88ec2b03c1d18b428e45c58f5da1'
        #appName: 'Node.js Application'
      #}

    # Run the server
    env = (process.env.NODE_ENV || 'development').capitalize()
    Bot.server.listen(Bot.express.settings.port)
    console.log("Http server listening on http://0.0.0.0:#{Bot.express.settings.port}")
    console.log("NaggyBot App server started in #{env} environment")

    #taskWorker = ->
      #Bot.db.reviews.executeAll {}, (err) ->
        #throw new Error(err) if err
        #setTimeout(taskWorker, 2000)

    #taskWorker() if Bot.express.settings.env == 'production'

