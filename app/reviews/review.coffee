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
    exec "wget -O #{path} #{url}", (err, stdout, stderr) ->
      return done(err) if err
      done()

  extract: (archive, path, done) ->
    exec "tar -xf #{archive} -C #{path} --strip-components=1", (err, stdout, stderr) ->
      return done(err) if err
      done()

  # Pull a tagbar of reviewes pull request and untar it
  pull: (review, done) ->
    review.pull ||= {}
    repo = review.github.pull_request.head.repo

    # Get the user's token
    Bot.db.users.findByRepo repo, (err, user) ->
      return done(err) if err
      if !user
        review.error = "No user for repo #{repo.owner.login}/#{repo.name} found in database"
        return Bot.db.reviews.save review, done

      review.pull.url = "https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/tarball/#{review.github.pull_request.head.sha}?access_token=#{user.github.accessToken}"
      Bot.db.reviews.save review, (err) ->
        return done(err) if err

        tmp.tmpName keep: false, (err, path) ->
          return done(err) if err

          fs.mkdirs path, (err) ->
            return done(err) if err
            review.pull.path = path
            review.pull.archive = pathUtil.join(review.pull.path, 'ar.tar')

            Bot.db.reviews.save review, (err) ->
              return done(err) if err
              Bot.db.reviews.download review.pull.url, review.pull.archive, (err) ->
                return done(err) if err
                review.pull.source = pathUtil.join(review.pull.path, 'source')
                fs.mkdirs review.pull.source, (err) ->
                  return done(err) if err
                  Bot.db.reviews.extract review.pull.archive, review.pull.source, (err) ->
                    return done(err) if err
                    request {
                      headers: { 'Accept': 'application/vnd.github.diff', 'User-Agent': 'NodeJS HTTP Client' }
                      url: "https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/pulls/#{review.number}?access_token=#{user.github.accessToken}"
                    }, (err, response, body) ->
                      return done(err) if err
                      review.pull.diff = body
                      Bot.db.reviews.save review, (err) ->
                        return done(err) if err
                        done(null, review)

  analyze: (review, done) ->
    done(null, review)

  push: (review, done) ->
    done(null, review)
})
