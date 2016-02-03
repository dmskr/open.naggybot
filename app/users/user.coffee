collection = Bot.db.collection('users')

emailRegExp = /^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/

Bot.db.users = {
  save: (user, done) ->
    self = this
    user.createdAt ||= new Date()
    user.updatedAt = new Date()
    Bot.db.keywords.fromText [
      user.username
      user.email
    ].join(" "), (err, keywords) ->
      user.keywords = keywords
      collection.save user, strict: true , done
  
  hashPassword: (password, done) ->
    return done(null, null) if !password || password.length == 0
    bcrypt.genSalt 10, (err, salt) ->
      bcrypt.hash password.toString(), salt, done

  validate: (user, done) ->
    async.parallel {
      username: (next) ->
        if !user.username || user.username.isBlank()
          return next(null, "Username is required")
        next()
      email: (next) -> Bot.db.users.validateEmail(user, next)
      password: (next) -> Bot.db.users.validatePassword(user, next)
    }, (err, results) ->
      return done(err) if err
      keys = Object.keys(results).findAll (key) -> !!results[key]
      done(null, Object.select(results, keys))

  validateEmail: (user, done) ->
    if !user.email || user.email.isBlank()
      return done(null, "Email is required")
    if !user.email.match(emailRegExp)
      return done(null, "Email '#{user.email}' doesn't look like email. Please check if you have a missprint.")
    done()

  validatePassword: (user, done) ->
    if !user.password || user.password.isBlank()
      return done(null, "Password is required")
    if 'confirmationPassword' of user
      if !user.confirmationPassword
        return done(null, 'Please confirm your password')
      if user.confirmationPassword != user.password
        return done(null, 'Password confirmation should match the password')
    done()

  autocomplete: (text, done) ->
    Bot.db.keywords.toConditions text, (err, conditions) ->
      return done(err) if err
      return done(null, [])  unless conditions
      Bot.db.users.find(conditions).limit(10).toArray done

  findByRepo: (repo, done) ->
    Bot.db.repos.find({ 'github.name': repo.name, 'github.owner.login': repo.owner.login, active: true }).toArray (err, repos) ->
      return done(err) if err
      return done() if !repos || !repos.first() || !repos.first().user
      Bot.db.users.findById repos.first().user, done
}

