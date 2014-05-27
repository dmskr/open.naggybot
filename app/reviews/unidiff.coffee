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
      range.removed.lines.each (line) ->
        line.diffindex = diffindex + line.diffindex
      range.added.lines.each (line) ->
        line.diffindex = diffindex + line.diffindex
      diffindex += range.lines.length

    done null,
      name: name
      ranges: result


exports.parseRange = (lines, done) ->
  matches = lines.first().match(/^(@@.+@@\s?)(.+)?/)
  lines[0] = matches[2] or null
  
  scopes = matches[1].match(/^@@\s\-(\d+),(\d+)\s\+(\d+),(\d+)\s@@\s?$/)
  result =
    removed:
      from: scopes[1].toNumber()
      total: scopes[2].toNumber()
      lines: []
    added:
      from: scopes[3].toNumber()
      total: scopes[4].toNumber()
      lines: []
    lines: lines

  [result.removed, result.added].each (s) ->
    s.to = s.from + s.total

  lines.each (line, index) ->
    if line
      blocks = [result.removed, result.added]
      if line[0] is "+"
        blocks = [result.added]
      else if line[0] is "-"
        blocks = [result.removed]
      blocks.each (block) ->
        block.lines.push
          action: line[0]
          diffindex: index + 1
          text: line.slice(1)

  done null, result

