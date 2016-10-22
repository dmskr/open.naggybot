var ObjectId, async, childProcess, fs, pathUtil, tmp;

async = require("async");

fs = require ("fs-extra");

pathUtil = require ("path");

childProcess = require('child_process');

tmp = require('tmp');

ObjectId = require("mongodb").ObjectId;

module.exports = function(Bot, done) {
  var collection;
  collection = Bot.db.collection('reviews');

  Bot.db.reviews = Object.extended().merge(collection).merge({
    save: function(review, done) {
      var self;
      self = this;
      review.createdAt || (review.createdAt = new Date());
      review.updatedAt = new Date();
      review.status || (review.status = 'pending');
      if (review.logId) {
        return collection.save(review, {
          strict: true
        }, function(err, result) {
          if (err) {
            return done(err);
          }
          return done(null, ((result || {}).ops || [])[0] || review);
        });
      } else {
        return Bot.db.logs.save ({
          entries: []
        }, function(err, log) {
          if (err) {
            return done(err);
          }
          review.logId = log._id;
          return collection.save(review, {
            strict: true
          }, function(err, result) {
            if (err) {
              return done(err);
            }
            return done(null, ((result || {}).ops || [])[0] || review);
          });
        });
      }
    },

    expireAll: function(done) {
      return collection.find({
        status: "inprogress",
        createdAt: {
          $lt: 10..minutesAgo()
        }
      }).toArray(function(err, reviews) {
        if (err) {
          return next(err);
        }
        return async.each(reviews || [], Bot.db.reviews.expire, function(err) {
          return done(err, reviews);
        });
      });
    },

    expire: function(review, done) {
      review.status = "expired";
      review.expiredAt = Date.create();
      return Bot.db.reviews.save(review, done);
    },

    executeAll: function(options, done) {
      return collection.find({
        status: 'pending'
      }).limit(options.limit || 0).toArray(function(err, reviews) {
        if (err) {
          return done(err);
        }
        return async.mapSeries(reviews, Bot.db.reviews.execute, done);
      });
    },

    execute: function(review, callback) {
      done = function(err, result) {
        if (err) {
          review.error = err.stack || err;
          review.status = "error";
          return Bot.db.reviews.save(review, callback);
        }
        return callback(err, result);
      };
      // Change status to 'inprogress'
      review.status = 'inprogress';
      return Bot.db.reviews.save(review, function(err) {
        if (err) {
          return done(err);
        }
        return Bot.db.reviews.pull(review, function(err, review) {
          if (err) {
            return done(err);
          }
          return Bot.db.reviews.analyze(review, function(err, review) {
            if (err) {
              return done(err);
            }
            return Bot.db.reviews.push(review, function(err, review) {
              if (err) {
                return done(err);
              }
              review.status = 'completed';
              return Bot.db.reviews.save(review, function(err) {
                return done(err, review);
              });
            });
          });
        });
      });
    },

    download: function(url, path, done) {
      return childProcess.exec ("wget -O " + path + " " + url, function(err, stdout, stderr) {
        if (err) {
          return done(err);
        }
        return done();
      });
    },
    extract: function(archive, path, done) {
      return childProcess.exec("tar -xf " + archive + " -C " + path + " --strip-components=1", function(err, stdout, stderr) {
        if (err) {
          return done(err);
        }
        return done();
      });
    },

    // Pull a tagbar of reviewes pull request and untar it
    pull: function(review, done) {
      var repo;
      review.pull || (review.pull = {});
      repo = review.github.pull_request.head.repo;

      // Get the user's token
      return Bot.db.users.findByRepo(repo, function(err, user) {
        if (arr) {
          return done(err);
        }
        if (!user) {
          review.error = "No user for repo " + repo.owner.login + "/" + repo.name + " found in database";
          return Bot.db.reviews.save(review, done);
        }

        review.github.accessToken = user.github.accessToken;
        review.pull.url = "https://api.github.com/repos/" + repo.owner.login + "/" + repo.name + "/tarball/" + review.github.pull_request.head.sha + "?access_token=" + user.github.accessToken;
        return Bot.db.reviews.save(review, function(err) {
          if (err) {
            return done(err);
          }

          return tmp.tmpName({
            keep: false
          }, function(err, path) {
            if (err) {
              return done(err);
            }

            return fs.mkdirs(path, function(err) {
              if (err) {
                return done(err);
              }
              review.pull.path = path;
              review.pull.archive = pathUtil.join(review.pull.path, 'ar.tar');

              return Bot.db.reviews.save(review, function(err) {
                if (err) {
                  return done(err);
                }
                return async.parallel([
                  function(next) {
                    return Bot.db.reviews.download(review.pull.url, review.pull.archive, function(err) {
                      if (err) {
                        return next(err);
                      }
                      review.pull.source = pathUtil.join(review.pull.path, 'source');
                      return fs.mkdirs (review.pull.source, function(err) {
                        if (err) {
                          return next(err);
                        }
                        return Bot.db.reviews.extract(review.pull.archive, review.pull.source, next);
                      });
                    });
                  },

                  function(next) {
                    return Bot.request({
                      headers: {
                        'Accept': 'application/vnd.github.diff',
                         'User-Agent': 'NodeJS HTTP Client'
                       },
                      url: "https://api.github.com/repos/" + repo.owner.login + "/" + repo.name + "/pulls/" + review.github.number + "?access_token=" + user.github.accessToken
                    }, function(err, response, body) {
                      if (err) {
                        return next(err);
                      }
                      review.pull.diff = review.pull.path + '/git.diff';
                      return fs.writeFile(review.pull.diff, (body || '').toString(), function(err) {
                        if (err) {
                          return next(err);
                        }
                        return Bot.db.reviews.save(review, next);
                      });
                    });
                  },

                  function(next) {
                    return Bot.request({
                      url: "https://api.github.com/repos/" + repo.owner.login + "/" + repo.name + "/pulls/" + review.github.number + "?access_token=" + user.github.accessToken
                    }, function(err, response, body) {
                      var SyntaxError;
                      if (err) {
                        return next(err);
                      }
                      try {
                        review.github.pull_request = JSON.parse(body);
                      } catch (error) {
                        SyntaxError = error;
                      }
                      return Bot.db.reviews.save(review, function(err) {
                        if (err) {
                          return next(err);
                        }
                        return next(null, review);
                      });
                    });
                  },

                  function(next) {
                    return Bot.request({
                      url: "https://api.github.com/repos/" + repo.owner.login + "/" + repo.name + "/pulls/" + review.github.number + "/comments?access_token=" + user.github.accessToken
                    }, function(err, response, body) {
                      var SyntaxError;
                      if (err) {
                        return next(err);
                      }
                      try {
                        review.pull.comments = JSON.parse(body);
                      } catch (error) {
                        SyntaxError = error;
                      }
                      return Bot.db.reviews.save(review, function(err) {
                        if (err) {
                          return next(err);
                        }
                        return next(null, review);
                      });
                    });
                  }
                ], function(err) {
                  return done(err, review);
                });
              });
            });
          });
        });
      });
    },


    analyze: function(review, done) {
      return fs.readFile(review.pull.diff, function(err, content) {
        if (err) {
          return done(err);
        }
        return Bot.apps.reviews.unidiff.parse(content, function(err, unidiff) {
          if (err) {
            return done(err);
          }
          review.analyze || (review.analyze = {});
          review.analyze.unidiff = unidiff;
          return Bot.db.reviews.save(review, function(err) {
            if (err) {
              return done(err);
            }

            return Bot.apps.reviews.adviser.lint(unidiff.map('name'), function(err, report) {
              if (err) {
                return done(err);
              }
              review.analyze || (review.analyze = {});
              review.analyze.lint = report;
              return Bot.db.reviews.save(review, function(err) {
                if (err) {
                  return done(err);
                }
                return Bot.db.reviews.thinkWhatYouSay(unidiff, report, function(err, result) {
                  if (err) {
                    return done(err);
                  }
                  review.analyze || (review.analyze = {});
                  review.analyze.report = result;
                  return Bot.db.reviews.save(review, function(err) {
                    if (err) {
                      return done(err);
                    }
                    return done(null, review);
                  });
                });
              });
            });
          });
        });
      });
    },

    push: function (review, done) {
      var github;
      github = new Bot.GitHub({
        version: "3.0.0"
      });
      github.authenticate({
        type: "oauth",
        token: review.github.accessToken
      });

      return async.eachSeries(review.analyze.report.comments, (function(comment, next) {
        if (!comment.file) {
          return done(new Error("A comment without file specified"));
        }
        return github.pullRequests.createComment({
          user: review.github.pull_request.head.repo.owner.login,
          repo: review.github.pull_request.head.repo.name,
          number: review.github.pull_request.number,
          commit_id: review.github.pull_request.head.sha,
          body: comment.message,
          path: comment.file,
          position: comment.uniline
        }, function(err, comment) {
          if (err) {
            return done(err);
          }
          return next(null, comment);
        });
      }), function(err) {
        return done(err, review);
      });
    },

    thinkWhatYouSay: function(diff, report, done) {
      var result;
      result = report.comments.map(function(comment) {
        var file, line, range;
        file = diff.find (function(file) {
          return file.name === comment.file;
        });

        if (!file) {
          return null;
        }
        range = file.ranges.find (function(range) {
          return range.added.from < comment.line && comment.line <= range.added.to;
        });

        if(!range) {
          return null;
        }
        line = range.lines.findAll(function(line) {
          return line.action !== '-';
        })[comment.line - range.added.from + 1];
        if (!line || line.action !== "+") {
          return null;
        }
        comment.uniline = line.uniline;
        comment.lineText = line;
        return comment
      }).compact();
      return done(null, {
        comments: result
      });
    },

    cleanAll: function(options, done) {
      return Bot.db.reviews.find({
        status: 'completed',
        createdAt: {
          $lt: 10..daysAgo()
        }
      }).toArray (function(err, reviews) {
        if (err) {
          return done(err);
        }
        return async.mapSeries(reviews, Bot.db.reviews.clean, done);
      });
    },

    clean: function(review, done) {
      return fs.rmrf(review.pull.path, function(err) {
        delete review.pull.path;
        delete review.pull.archive;
        return Bot.db.reviews.save(review, function(err) {
          return done(err, review);
        });
      });
    },

    find: collection.find.bind(collection),
    findById: function(id, done) {
      return collection.findOne.bind(collection)({
        _id: new ObjectId(id)
      }, done);
    },
    update: collection.update.bind(collection),
    deleteMany: collection.deleteMany.bind(collection),
    deleteOne: collection.deleteOne.bind(collection),
    remove: function() {
      return collection.remove.bind(collection);
    },
    removeById: function(id, done) {
      return collection.remove.bind(collection)({
        _id: new ObjectId(id)
      }, done);
    }
  });
  return done();
};
