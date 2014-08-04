collection = Bot.db.collection('logs')
skin = save: collection.save

Bot.db.bind('logs').bind({
  save: (log, done) ->
    log.createdAt = Date.create() if !log.createdAt
    log.updatedAt = Date.create()
    skin.save.call this, log, strict: true , done

  write: (obj, text, done) ->
    return done('No logId found') if !obj.logId
    Bot.db.logs.updateById obj.logId, { $addToSet: { entries: { text: text, createdAt: Date.create() }}}, done
})

