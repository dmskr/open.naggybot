exports.notFound = (req, res, next) ->
  if req.is('json')
    res.json('200', { errors: { _id: 'The page is not found', code: 404 }})
  else
    res.statusCode = '404'
    res.render(Bot.root + "/app/shared/public/404.jade")

exports.error = (req, res, next) ->
  if req.is('json')
    res.json('200', { errors: { _id: 'Something went wrong', code: 500 }})
  else
    res.statusCode = '500'
    res.render(Bot.root + "/app/shared/public/500.jade")

exports.index = (req, res, next) ->
  return res.redirect('/private') if req.user
  res.render(Bot.root + "/app/shared/public/index.jade")

