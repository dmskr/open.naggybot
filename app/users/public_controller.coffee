module.exports = (Bot, done) ->
  exports = {}
  exports.new = (req, res, next) ->
    res.render Bot.root + '/app/users/public/signup.jade'

  exports.create = (req, res, next) ->
    user = req.body.user
    user.email = (user.email || '').toLowerCase()
    console.log(Bot.db.users)
    Bot.db.users.validate user, (err, errors) ->
      return next(err) if err
      renderError = (error) ->
        return if !error
        if req.is('json')
          return res.json('200', { errors: error})
        else
          req.flash('error', Object.values(error).join("<br />"))
          return res.render("#{Bot.root}/app/users/public/signup.jade", user: user)

      if Object.size(errors) > 0
        renderError(errors)
      else
        Bot.db.users.find({ username: user.username }).toArray (err, users) ->
          if users && users.length > 0
            message = "User with the username already exists. Do you want to <a href=\"/forgot?email=#{((user || {}).email || '')}\">reset password</a>?"
            renderError({ _id: message })
          else
            Bot.db.users.hashPassword user.password, (err, password) ->
              return next(err) if err
              user.password = password
              delete user.confirmationPassword
              Bot.db.users.save user, (err, user) ->
                return next(err) if err
                req.login user, (err) ->
                  return next(err) if err
                  res.redirect '/private'

  done(null, exports)
