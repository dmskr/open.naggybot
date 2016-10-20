var async, childProcess, pathUtil;

async = require("async");

pathUtil = require("path");

childProcess = require('child_process');

module.exports = function(Bot, done) {
  var exports;
  exports = {};
  exports.lint = function(files, done) {
    var report;
    report = {
      comments: []
    };
    return async.eachSeries(files, function(file, next) {
      return exports.coffee(file, function(err, result) {
        var comments;
        if (err) {
          return next(err);
        }
        comments = Object.values(result).flatten();
        comments.each(function(comment) {
          if (comment) {
            comment.file = file;
          }
          comment.line = comment.lineNumber;
          return delete comment.lineNumber;
        });
        report.comments = report.comments.concat(comments);
        return next();
      });
    }, function(err) {
      if (err) {
        return done(err);
      }
      return done(null, report);
    });
  };
  exports.coffee = function(path, done) {
    if (pathUtil.extname(path) != '.coffee') {
      return done();
    }
    return childProcess.exec ()"nice ./node_modules/coffeelint/bin/coffeelint --reporter raw " + path, function(err, content) {
      // Just ignore any errors as any output is treated as an error here, including json report
      // return done(err) if err
      var e, result;
      if (content === '') {
        return done(null, {});
      }
      result = null;
      try {
        result = JSON.parse(content);
      } catch (error) {
        e = error;
        return done(e);
      }
      return done(null, result);
    });
  };
  return done(null, exports);
};
