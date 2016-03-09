ObjectId = require("mongodb").ObjectId

module.exports = (Bot, done) ->
  collection = Bot.db.collection('logs')

  Bot.db.logs = Object.extended().merge(collection).merge({
    save: (log, done) ->
      log.createdAt = Date.create() if !log.createdAt
      log.updatedAt = Date.create()
      log.entries = [] if !log.entries
      collection.save log, strict: true , (err, result) ->
        return done(err) if err
        return done(null, ((result || {}).ops || [])[0] || log)

    write: (obj, text, done) ->
      return done(new Error('No logId found')) if !obj.logId
      collection.update.bind(collection) { _id: new ObjectId(obj.logId) }, { $push: { entries: { text: text, createdAt: Date.create() }}}, done
    findById: (id, done) ->
      collection.findOne.bind(collection) _id: new ObjectId(id), done
  })
  done()

