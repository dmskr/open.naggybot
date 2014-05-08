collection = Skin.db.collection('users')
skin = save: collection.save

emailRegExp = /^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/

Skin.db.bind('users').bind({
  save: (user, done) ->
    user.createdAt ||= new Date()
    user.updatedAt = new Date()
    skin.save.call this, user, strict: true, done
  
  generatePassword: (password, done) ->
    return done(null, null) if !password || password.length == 0
    bcrypt.genSalt 10, (err, salt) ->
      bcrypt.hash password.toString(), salt, done

  validate: (user, done) ->
    errors = {}
    if !user.username || user.username.isBlank()
      errors.username = "Username is required"

    Skin.db.users.validatePassword user, (err, passerrors) ->
      return done(err) if err
      errors = Object.merge(errors, passerrors)
      done(null, errors)

  validateEmail: (user, done) ->
    errors = {}
    if !user.email || user.email.isBlank()
      errors.email = "Email is required"
    else if !user.email.match(emailRegexp)
      errors.email = "Email '#{user.email}' doesn't look like email. Please check if you have a missprint."
    done(null, errors)

  validatePassword: (user, done) ->
    errors = {}
    if (!user.password || user.password.isBlank())
      errors.password = "Password is required"
    else if('confirmationPassword' of user)
      if !user.confirmationPassword
        errors.confirmationPassword = 'Please confirm your password'
      else if user.confirmationPassword != user.password
        errors.confirmationPassword = 'Password confirmation does not match the password itself'
    done(null, errors)
})

