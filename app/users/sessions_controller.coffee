GITHUB_CLIENT_ID = "76f9ddbeb73de6823fab"
GITHUB_CLIENT_SECRET = "4850ec99a910c8f1a4d654880adebc84dbc243af"

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

exports.del = (req, res, next) ->
  req.logout()
  res.redirect '/'

exports.authGitHub = (accessToken, refreshToken, profile, done) ->
  Bot.db.users.find({ 'provider.github.id': profile.id }).limit(1).toArray (err, users) ->
    return done(err) if err

    user = users.first() || {}
    user.provider ||= {}
    user.provider.github ||= {}
    user.provider.github.displayName = profile.displayName
    user.provider.github.username = profile.username
    user.provider.github.emails = (profile.emails || []).map((email) -> email.value).findAll((email) -> !!email)
    user.provider.github.avatar_url = (profile._json || {}).avatar_url
    user.provider.github.gravatar_id = (profile._json || {}).gravatar_id
    user.provider.github.accessToken = accessToken
    user.provider.github.refreshToken = refreshToken
    Bot.db.users.save user, (err) ->
      return done(err, user)

passport.use(new GitHubStrategy {
    clientID: GITHUB_CLIENT_ID
    clientSecret: GITHUB_CLIENT_SECRET
    callbackURL: "http://127.0.0.1:8081/auth/github/callback"
    scope: ['user:email', 'repo', 'admin:repo_hook']
  }, exports.authGitHub)

passport.serializeUser (user, done) ->
  done(null, user._id)

passport.deserializeUser (id, done) ->
  Bot.db.users.findById(id, done)
