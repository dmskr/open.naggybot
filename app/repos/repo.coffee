collection = Bot.db.collection('repos')
skin = save: collection.save

Bot.db.bind('repos').bind({
  save: (repo, done) ->
    repo.createdAt ||= new Date()
    repo.updatedAt = new Date()
    skin.save.call this, repo, strict: true , done
})
    
