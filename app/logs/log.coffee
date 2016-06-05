ObjectId = require("mongodb").ObjectId
w = require("when")

module.exports = (Bot, done) ->
  collection = Bot.db.collection('logs')

  Bot.db.logs = Object.extended().merge(collection).merge({
    save: (log) ->
      log.createdAt = Date.create() if !log.createdAt
      log.updatedAt = Date.create()
      log.entries = [] if !log.entries
      return collection.save(log, strict: true).then (result) ->
        return ((result || {}).ops || [])[0] || log

    write: (obj, text) ->
      return w.reject(new Error('No logId found')) if !obj.logId
      return collection.update.bind(collection) { _id: new ObjectId(obj.logId) }, { $push: { entries: { text: text, createdAt: Date.create() }}}

    findById: (id) ->
      return collection.findOne.bind(collection) _id: new ObjectId(id)
  })
  done()

