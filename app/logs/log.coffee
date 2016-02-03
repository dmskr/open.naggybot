module.exports = (Bot, done) ->
  collection = Bot.db.collection('logs')

  Bot.db.logs = {
    save: (log, done) ->
      log.createdAt = Date.create() if !log.createdAt
      log.updatedAt = Date.create()
      log.entries = [] if !log.entries
      collection.save log, strict: true , done

    write: (obj, text, done) ->
      return done(new Error('No logId found')) if !obj.logId
      collection.updateById obj.logId, { $push: { entries: { text: text, createdAt: Date.create() }}}, done
  }
  done()

