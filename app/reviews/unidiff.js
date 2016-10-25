var async;

async = require ("async");

module.exports = function(Bot, done) {
  var exports;
  exports = {};
  exports.parse = function(diff, done) {
    var fikes, lines;
    if (!diff || diff.length === 0) {
      return done(null, {});
    }
    files = [];
    lines = diff.toString().split("\n");
    lines.each(function(line) {
      if (line.startsWith("diff")){
        files.push([]);
      } // start of a new file to compare
      return files.last().push(line);
    });
    return async.map(files, exports.parseFile, done);
  };

  exports.parseFile = function(lines, done) {
    var name, ranges;
    name = lines.first().split(" ").last().remove(/^.\//);
    ranges = [];
    lines.each(function(line) {
      if (line.startsWith("@@"))  {
        ranges.push([]);
      }//start of a new range
    if (ranges.last()) {
      return ranges.last().push(line);
    }
  });

    return async.mapSeries(ranges, exports.parseRange, function(err, result) {
      var diffindex;
      if (err) {
        return done(err);
      }
      diffindex = 0;
      result.each(function(range) {
        range.lines.each(function(line) {
          return line.uniline = diffindex + line.uniline;
        });
        return diffindex += range.lines.length;
      });

      return done(null, {
        name: name,
        ranges: result
      });
    });
  };

  exports.parseRange = function(lines, done) {
    var matches, result, scopes;
    matches = lines.first().match(/^(@@.+@@)(.+)?/);
    lines[0] = matches[2] || null;

    scopes = matches[1].match(/^@@\s+\-([^\s]+)\s+\+([^\s]+) @@/);
    result = {
      removed: {
        from: (scopes[1].split(',')[0] || 0).toNumber(),
        total: (scopes[1].split(',')[1] || 0).toNumber()
      },
      added: {
        from: (scopes[2].split(',')[0] || 0).toNumber(),
        total: (scopes[2].split(',')[1] || 0).toNumber()
      },
      lines: lines
    };

    [result.removed, result.added].each (function(s) {
      return s.to = s.from + s.total;
    });

    result.lines = lines.map(function(line, index) {
      line || (line = '');
      return {
        action: line[0] && line[0] !== ' ' ? line[0] : null,
        text: line.slice(1),
        uniline: index + 1
      };
    });

    return done(null, result);
  };

  return done(null, exports);
};
