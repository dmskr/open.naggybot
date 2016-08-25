async = require "async"
fs = require "fs-extra"
pathUtil = require "path"
childProcess = require('child_process')
tmp = require 'tmp'

ObjectId = require("mongodb").ObjectId
module.exports = (Bot, done) ->
  collection = Bot.db.collection('reviews')

  Bot.db.reviews = Object.extended().merge(collection).merge({
    save: (review, done) ->
      self = this
      review.createdAt ||= new Date()
      review.updatedAt = new Date()
      review.status ||= 'pending'
      if review.logId
        collection.save review, { strict: true }, (err, result) ->
          return done(err) if err
          return done(null, ((result || {}).ops || [])[0] || review)
      else
        Bot.db.logs.save { entries: [] }, (err, log) ->
          return done(err) if err
          review.logId = log._id
          collection.save review, strict: true , (err, result) ->
            return done(err) if err
            return done(null, ((result || {}).ops || [])[0] || review)

    expireAll: (done) ->
      collection.find(
        status: "inprogress"
        createdAt:
          $lt: (10).minutesAgo()
      ).toArray (err, reviews) ->
        return next(err) if err
        async.each reviews or [], Bot.db.reviews.expire, (err) ->
          done(err, reviews)

    expire: (review, done) ->
      review.status = "expired"
      review.expiredAt = Date.create()
      Bot.db.reviews.save review, done

    executeAll: (options, done) ->
      collection.find(status: 'pending').limit(options.limit || 0).toArray (err, reviews) ->
        return done(err) if err
        async.mapSeries reviews, Bot.db.reviews.execute, done

    execute: (review, callback) ->
      done = (err, result) ->
        if err
          review.error = err.stack || err
          review.status = "error"
          return Bot.db.reviews.save review, callback
        return callback(err, result)

      # Change status to 'inprogress'
      review.status = 'inprogress'
      Bot.db.reviews.save review, (err) ->
        return done(err) if err
        Bot.db.reviews.pull review, (err, review) ->
          return done(err) if err
          Bot.db.reviews.analyze review, (err, review) ->
            return done(err) if err
            Bot.db.reviews.push review, (err, review) ->
              return done(err) if err
              review.status = 'completed'
              Bot.db.reviews.save review, (err) ->
                done(err, review)

    download: (url, path, done) ->
      childProcess.exec "wget -O #{path} #{url}", (err, stdout, stderr) ->
        return done(err) if err
        done()

    extract: (archive, path, done) ->
      childProcess.exec "tar -xf #{archive} -C #{path} --strip-components=1", (err, stdout, stderr) ->
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
                async.parallel [
                  (next) ->
                    Bot.db.reviews.download review.pull.url, review.pull.archive, (err) ->
                      return next(err) if err
                      review.pull.source = pathUtil.join(review.pull.path, 'source')
                      fs.mkdirs review.pull.source, (err) ->
                        return next(err) if err
                        Bot.db.reviews.extract review.pull.archive, review.pull.source, next
                        
                  (next) ->
                    Bot.request {
                      headers: { 'Accept': 'application/vnd.github.diff', 'User-Agent': 'NodeJS HTTP Client' }
                      url: "https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/pulls/#{review.github.number}?access_token=#{user.github.accessToken}"
                    }, (err, response, body) ->
                      return next(err) if err
                      review.pull.diff = review.pull.path + '/git.diff'
                      fs.writeFile review.pull.diff, (body || '').toString(), (err) ->
                        return next(err) if err
                        Bot.db.reviews.save review, next

                  (next) ->
                    Bot.request url: "https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/pulls/#{review.github.number}?access_token=#{user.github.accessToken}", (err, response, body) ->
                      return next(err) if err
                      try
                        review.github.pull_request = JSON.parse(body)
                      catch SyntaxError
                      Bot.db.reviews.save review, (err) ->
                        return next(err) if err
                        next(null, review)

                  (next) ->
                    Bot.request url: "https://api.github.com/repos/#{repo.owner.login}/#{repo.name}/pulls/#{review.github.number}/comments?access_token=#{user.github.accessToken}", (err, response, body) ->
                      return next(err) if err
                      try
                        review.pull.comments = JSON.parse(body)
                      catch SyntaxError
                      Bot.db.reviews.save review, (err) ->
                        return next(err) if err
                        next(null, review)

                ], (err) ->
                  done(err, review)


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
      github = new Bot.GitHub(version: "3.0.0")
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
      ), (err) -> done(err, review)

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
      done null, comments: result

    cleanAll: (options, done) ->
      Bot.db.reviews.find({ status: 'completed', createdAt: { $lt: (10).daysAgo() }}).toArray (err, reviews) ->
        return done(err) if err
        async.mapSeries reviews, Bot.db.reviews.clean, done

    clean: (review, done) ->
      fs.rmrf review.pull.path, (err) ->
        delete review.pull.path
        delete review.pull.archive
        Bot.db.reviews.save review, (err) ->
          done err, review

    find: collection.find.bind(collection)
    findById: (id, done) ->
      collection.findOne.bind(collection) _id: new ObjectId(id), done
    update: collection.update.bind(collection)
    deleteMany: collection.deleteMany.bind(collection)
    deleteOne: collection.deleteOne.bind(collection)
    remove: -> collection.remove.bind(collection)
    removeById: (id, done) ->
      collection.remove.bind(collection) _id: new ObjectId(id), done
  })
  done()

