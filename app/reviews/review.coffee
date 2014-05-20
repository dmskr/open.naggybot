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
})
