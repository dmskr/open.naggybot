async = require "async"

module.exports = (Bot, done) ->
  exports = {}
  exports.parse = (diff, done) ->
    return done(null, {}) if !diff || diff.length == 0
    files = []
    lines = diff.toString().split("\n")
    lines.each (line) ->
      files.push [] if line.startsWith("diff") # start of a new file to compare
      files.last().push line
    async.map files, exports.parseFile, done

  exports.parseFile = (lines, done) ->
    name = lines.first().split(" ").last().remove(/^.\//)
    ranges = []
    lines.each (line) ->
      ranges.push []  if line.startsWith("@@") # start of a new range
      ranges.last().push line  if ranges.last()

    async.mapSeries ranges, exports.parseRange, (err, result) ->
      return done(err)  if err
      diffindex = 0
      result.each (range) ->
        range.lines.each (line) ->
          line.uniline = diffindex + line.uniline
        diffindex += range.lines.length

      done null,
        name: name
        ranges: result

  exports.parseRange = (lines, done) ->
    matches = lines.first().match(/^(@@.+@@)(.+)?/)
    lines[0] = matches[2] or null
    
    scopes = matches[1].match(/^@@\s+\-([^\s]+)\s+\+([^\s]+) @@/)
    result =
      removed:
        from: (scopes[1].split(',')[0] || 0).toNumber()
        total: (scopes[1].split(',')[1] || 0).toNumber()
      added:
        from: (scopes[2].split(',')[0] || 0).toNumber()
        total: (scopes[2].split(',')[1] || 0).toNumber()
      lines: lines

    [result.removed, result.added].each (s) ->
      s.to = s.from + s.total

    result.lines = lines.map (line, index) ->
      line ||= ''
      action: if line[0] && line[0] != ' ' then line[0] else null
      text: line.slice(1)
      uniline: index + 1

    done null, result

  done(null, exports)
