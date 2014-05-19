collection = Bot.db.collection('reviews')
skin = save: collection.save

Bot.db.bind('reviews').bind({
  save: (review, done) ->
    review.createdAt ||= new Date()
    review.updatedAt = new Date()
    skin.save.call this, review, strict: true , done

})
