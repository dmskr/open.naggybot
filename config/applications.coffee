Skin.apps = {} if !Skin.apps

apps = Skin.apps
files = fs.readdirSync("#{Skin.root}/app").findAll (name) ->
  name != '.' && name != '..'

files.each (name) ->
  apps[name] ||= {}
  apps[name].controller ||= {}
  
  # Setup public/private/admin controllers
  ['admin', 'public', 'private'].each (role) ->
    path = "#{Skin.root}/app/#{name}/#{role}_controller"
    if fs.existsSync("#{path}.coffee")
      apps[name].controller[role] = require(path)

  # Setup default model if exist
  model = "#{Skin.root}/app/#{name}/#{name.singularize()}"
  if fs.existsSync("#{model}.coffee")
    require(model)

# Additional models
require "#{Skin.root}/app/shared/keywords"

# Additional controllers out of public/private/admin scheme
apps.users.controller.sessions = require("../app/users/sessions_controller")

# Util function used in routes
global.require_user = (req, res, next) ->
  return next(new Error(401)) if !req.user
  next()

# Set routes
files.each (name) ->
  apps[name].routes = require("../app/#{name}/routes")
  apps[name].routes.route(Skin)

# The 404 Route (ALWAYS Keep this as the last route)
if Skin.apps.shared
  Skin.get('/*', Skin.apps.shared.controller.public.notFound)
  Skin.post('/*', Skin.apps.shared.controller.public.notFound)


