ObjectId = require("mongodb").ObjectId

module.exports = (Bot, done) ->
  collection = Bot.db.collection('repos')

  Bot.db.repos = Object.extended().merge(collection).merge({
    save: (repo, done) ->
      repo.createdAt ||= new Date()
      repo.updatedAt = new Date()
      collection.save repo, strict: true , (err, result) ->
        return done(err) if err
        return done(null, ((result || {}).ops || [])[0] || repo)
    find: collection.find
    findById: (id, done) ->
      collection.findOne _id: new ObjectId(id), done
  })
  done()
      
