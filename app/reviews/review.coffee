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

      review.github.accessToken = user.github.accessToken
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
                      url: "https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/pulls/#{review.github.number}?access_token=#{user.github.accessToken}"
                    }, (err, response, body) ->
                      return done(err) if err
                      review.pull.diff = review.pull.path + '/git.diff'
                      fs.writeFile review.pull.diff, (body || '').toString(), (err) ->
                        return done(err) if err
                        Bot.db.reviews.save review, (err) ->
                          return done(err) if err
                          request url: "https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/pulls/#{review.github.number}?access_token=#{user.github.accessToken}", (err, response, body) ->
                            return done(err) if err
                            try
                              review.github.pull_request = JSON.parse(body)
                            catch SyntaxError
                            Bot.db.reviews.save review, (err) ->
                              return done(err) if err
                              done(null, review)

  analyze: (review, done) ->
    fs.readFile review.pull.diff, (err, content) ->
      return done(err) if err
      Bot.apps.reviews.unidiff.parse content, (err, unidiff) ->
        return done(err) if err
        review.analyze ||= {}
        review.analyze.unidiff = unidiff
        Bot.db.reviews.save review, (err) ->
          return done(err) if err

          Bot.apps.reviews.adviser.lint unidiff.map('name'), (err, report) ->
            return done(err) if err
            review.analyze ||= {}
            review.analyze.lint = report
            Bot.db.reviews.save review, (err) ->
              return done(err) if err
              Bot.db.reviews.thinkWhatYouSay unidiff, report, (err, result) ->
                return done(err) if err
                review.analyze ||= {}
                review.analyze.report = result
                Bot.db.reviews.save review, (err) ->
                  return done(err) if err
                  done(null, review)

  push: (review, done) ->
    github = new GitHub(version: "3.0.0")
    github.authenticate
      type: "oauth"
      token: review.github.accessToken

    async.eachSeries review.analyze.report.comments, ((comment, next) ->
      return done(new Error("A comment without file specified")) unless comment.file
      github.pullRequests.createComment {
        user: review.github.pull_request.head.repo.owner.login
        repo: review.github.pull_request.head.repo.name
        number: review.github.pull_request.number
        commit_id: review.github.pull_request.head.sha
        body: comment.message
        path: comment.file
        position: comment.uniline
      }, (err, comment) ->
        return done(err) if err
        next null, comment
    ), done

  thinkWhatYouSay: (diff, report, done) ->
    result = report.comments.map (comment) ->
      file = diff.find (file) ->
        file.name is comment.file

      return null unless file
      range = file.ranges.find (range) ->
        range.added.from < comment.line and comment.line <= range.added.to

      return null  unless range
      line = range.lines.findAll((line) -> line.action != '-')[comment.line - range.added.from + 1]
      return null  if not line or line.action isnt "+"
      comment.uniline = line.uniline
      comment.lineText = line
      comment
    .compact()
    done null, result
})



