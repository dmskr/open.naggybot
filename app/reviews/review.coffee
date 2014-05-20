collection = Bot.db.collection('reviews')
skin = save: collection.save

Bot.db.bind('reviews').bind({
  save: (review, done) ->
    review.createdAt ||= new Date()
    review.updatedAt = new Date()
    review.status ||= 'pending'
    skin.save.call this, review, strict: true , done

  expireAll: (done) ->
    Bot.db.reviews.find(
      status: "inprogress"
      createdAt:
        $lt: (10).minutesAgo()
    ).toArray (err, reviews) ->
      return next(err)  if err
      async.each reviews or [], Bot.db.reviews.expire, (err) ->
        done(err, reviews)

  expire: (review, done) ->
    review.status = "expired"
    review.expiredAt = Date.create()
    Bot.db.reviews.save review, done

  executeAll: (options, done) ->
    Bot.db.reviews.find(status: 'pending').limit(options.limit || 0).toArray (err, reviews) ->
      return done(err) if err
      async.map reviews, Bot.db.reviews.execute, done

  execute: (review, done) ->
    # Change status to 'inprogress'
    review.status = 'inprogress'
    Bot.db.reviews.save review, (err) ->
      return done(err) if err
      # Pull
      Bot.db.reviews.pull review, (err, review) ->
        return done(err) if err
        Bot.db.reviews.analyze review, (err, review) ->
          return done(err) if err
          Bot.db.reviews.push review, (err, review) ->
            return done(err) if err
            done(null, review)

  pull: (review, done) ->
    done(null, review)

  analyze: (review, done) ->
    done(null, review)

  push: (review, done) ->
    done(null, review)
})
