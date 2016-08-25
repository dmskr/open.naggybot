passport = require("passport")
LocalStrategy = require('passport-local').Strategy
GitHubStrategy = require('passport-github').Strategy

module.exports = (Bot, done) ->
  exports = {}
  exports.new = (req, res, next) ->
    res.render Bot.root + '/app/users/public/login.jade'

  exports.create = (req, res, next) ->
    renderError = (error) ->
      if error
        if req.is('json')
          return res.json('200', { errors: { _id: error }})
        else
          req.flash('error', error)
          return res.render("#{Bot.root}/app/users/public/login.jade", email: req.body.email)
    
    email = (req.body.email || '').toLowerCase()
    if !((req.body.username || email) && req.body.password)
      return renderError('Missing Credentials')

    passport.authenticate('local', (err, user, info) ->
      return next(err) if err
      return renderError(Object.values(info.errors).join('<br/>')) if !user

      req.logIn user, (err) ->
        return next(err) if (err)
        return res.redirect('/private')
    )(req, res, next)

  exports.delete = (req, res, next) ->
    req.logout()
    res.redirect '/'

  exports.authGitHub = (accessToken, refreshToken, profile, done) ->
    Bot.db.users.find({ 'github.id': profile.id }).limit(1).toArray (err, users) ->
      return done(err) if err

      user = users.first() || {}
      user ||= {}
      user.github ||= { id: (profile || {}).id }
      user.github.displayName = profile.displayName
      user.github.username = profile.username
      user.github.emails = (profile.emails || []).map((email) -> email.value).findAll((email) -> !!email)
      user.github.avatar_url = (profile._json || {}).avatar_url
      user.github.gravatar_id = (profile._json || {}).gravatar_id
      user.github.accessToken = accessToken
      user.github.refreshToken = refreshToken
      user.displayName ||= profile.displayName
      user.username ||= profile.username
      user.email ||= user.github.emails[0]
      Bot.db.users.save user, (err) ->
        return done(err, user)

  #passport.use(new LocalStrategy (username, password, done) ->
    #Bot.db.users.find(username: username, (err, users) ->
      #return done(err) if err
      #user = users[0]
      #if !user return done('Username "' + username + '" does not exist')
      #Bot.db.users.hashPassword

    #)
    #done()
  #)
  passport.use(new GitHubStrategy {
      clientID: Bot.express.settings.github.client_id
      clientSecret: Bot.express.settings.github.secret
      callbackURL: "http://#{Bot.express.settings.host}/auth/github/callback"
      scope: ['user:email', 'repo', 'admin:repo_hook']
    }, exports.authGitHub)

  passport.serializeUser (user, done) ->
    done(null, user._id)

  passport.deserializeUser (id, done) ->
    Bot.db.users.findById(id, done)

  done(null, exports)
