module.exports = (Bot, done) ->
  collection = Bot.db.collection('repos')

  Bot.db.repos = {
    save: (repo, done) ->
      repo.createdAt ||= new Date()
      repo.updatedAt = new Date()
      collection.save repo, strict: true , done
  }
  done()
      
