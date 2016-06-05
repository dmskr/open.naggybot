ObjectId = require("mongodb").ObjectId

module.exports = (Bot, done) ->
  collection = Bot.db.collection('repos')

  Bot.db.repos = Object.extended().merge(collection).merge({
    save: (repo) ->
      repo.createdAt ||= new Date()
      repo.updatedAt = new Date()
      collection.save(repo, strict: true).then (result) ->
        ((result || {}).ops || [])[0] || repo
    find: collection.find
    findById: (id) ->
      collection.findOne _id: new ObjectId(id)
  })
  done()
      
