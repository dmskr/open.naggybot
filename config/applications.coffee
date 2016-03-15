fs = require('fs-extra')
async = require("async")

module.exports = (Bot, appsDone) ->
  Bot.apps = {} if !Bot.apps

  apps = Bot.apps
  files = fs.readdirSync("#{Bot.root}/app").findAll (name) ->
    !name.match(/^\./)

  async.each files, (name, next) ->
    apps[name] ||= {}
    apps[name].controller ||= {}
    
    # Setup public/private/admin controllers
    async.each ['admin', 'public', 'private'], (role, next) ->
      path = "#{Bot.root}/app/#{name}/#{role}_controller"
      if fs.existsSync("#{path}.coffee")
        require(path) Bot, (err, controller) ->
          return next(err) if err
          apps[name].controller[role] = controller
          return next()
      else next()
    , (err) ->
      return next(err) if err

      # Setup default model if exist
      model = "#{Bot.root}/app/#{name}/#{name.singularize()}"
      if fs.existsSync("#{model}.coffee")
        require(model) Bot, next
      else next()

  , (err) ->
    return appsDone(err) if err

    # Additional models
    require("#{Bot.root}/app/shared/keywords") Bot, ->
      # Additional controllers out of public/private/admin scheme
      async.parallel({
        sessions: (next) -> require("../app/users/sessions_controller")(Bot, next)
        service: (next) -> require("../app/reviews/service_controller")(Bot, next)
        adviser: (next) -> require("../app/reviews/adviser")(Bot, next)
        unidiff: (next) -> require("../app/reviews/unidiff")(Bot, next)
      }, (err, result) ->
        return appsDone(err) if err
        apps.users.controller.sessions = result.sessions
        apps.reviews.controller.service = result.service
        apps.reviews.adviser = result.adviser
        apps.reviews.unidiff = result.unidiff
      )

      # Util function used in routes
      Bot.require_user = (req, res, next) ->
        return next(new Error(401)) if !req.user
        next()

      Bot.require_admin = (req, res, next) ->
        return next(new Error(401)) if !req.user or !req.user.admin
        next()

      # Set routes
      files.each (name) ->
        apps[name].routes = require("../app/#{name}/routes")
        apps[name].routes.route(Bot)

      # The 404 Route (ALWAYS Keep this as the last route)
      if Bot.apps.shared
        Bot.express.get('/*', Bot.apps.shared.controller.public.notFound)
        Bot.express.post('/*', Bot.apps.shared.controller.public.notFound)

      appsDone()

