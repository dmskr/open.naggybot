passport.serializeUser (user, done) ->
  done(null, user._id)

passport.deserializeUser (id, done) ->
  Skin.db.users.findById(id, done)

passport.use new LocalStrategy (username, password, done) ->
  if (!username || username.length == 0)
    return done(null, false, user: null, errors: { username: 'Username is required' })

  Skin.db.users.find(username: username.toLowerCase()).toArray (err, users) ->
    return done(err) if (err)

    user = users.first()
    if !user
      message = "The username wasn't found. Do you want to <a href='/signup'>Signup</a>?"
      return done(null, false, errors: { username: message })

    # Load hash from your password DB.
    bcrypt.compare password, user.password, (err, res) ->
      return done(err) if err
      if !res
        return done(null, false, { user: user, errors: { password: 'Incorrect password'  }})
      else
        return done(null, user)


exports.new = (req, res, next) ->
  res.render Skin.root + '/app/users/public/login.jade'

exports.create = (req, res, next) ->
  renderError = (error) ->
    if error
      if req.is('json')
        return res.json('200', { errors: { _id: error }})
      else
        req.flash('error', error)
        return res.render("#{Skin.root}/app/users/public/login.jade", email: req.body.email)
  
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

