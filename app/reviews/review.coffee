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

  download: (url, path, done) ->
    filestream = fs.createWriteStream path
    filestream.on 'error', done
    filestream.on 'finish', done

    requeststream = request url: url, headers: { 'User-Agent': 'NodeJS HTTP Client' }
    requeststream.on 'error', done
    requeststream.pipe filestream

  extract: (archive, path, done) ->
    filestream = fstream.Writer({ path: path })
    filestream.on 'error', done
    filestream.on 'finish', done

    tarstream = tar.Extract(path: archive)
    tarstream.on 'error', done
    tarstream.pipe filestream

  # Pull a tagbar of reviewes pull request and untar it
  pull: (review, done) ->
    review.pull ||= {}
    repo = review.pull_request.head.repo
    # Get the user's token
    Bot.db.users.findByRepo repo, (err, user) ->
      return done(err) if err
      if !user
        review.error = "No user for repo #{repos.first().owner.login}/#{repos.first().name} found in database"
        return Bot.db.reviews.save review, done

      review.pull.url = "https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/pulls/#{number}?access_token=#{user.github.accessToken}"

      Bot.db.reviews.save review, (err) ->
        return done(err) if err

        tmp.tmpName keep: false, (err, path) ->
          return done(err) if err
          review.pull.path = path
          review.pull.archive = path.join(review.pull.path, 'ar.tar')

          Bot.db.reviews.save review, (err) ->
            return done(err) if err
            Bot.db.review.download review.pull.archive, path.join(review.pull.path, 'ar.tar'), (err) ->
              return done(err) if err
              Bot.db.review.extract review.pull.archive, (err) ->
                return done(err) if err
                done(null, review)

  analyze: (review, done) ->
    done(null, review)

  push: (review, done) ->
    done(null, review)
})
