require "../../shared/specs/helpers"

describe "UniDiff", ->
  describe 'parse', ->
    it "should not rise any errors if empty content is provided", (done) ->
      Bot.apps.reviews.unidiff.parse '', (err, result) ->
        return done(err) if err
        should.exist result
        result.should.eql {}
        done()

    describe 'result', ->
      [unidiff, content] = [null, null]
      before (done) ->
        fs.readFile Bot.root + '/app/reviews/specs/samples/pull.diff', (err, result) ->
          return done(err) if err
          content = result
          Bot.apps.reviews.unidiff.parse content, (err, result) ->
            return done(err) if err
            unidiff = result
            done()

      describe 'files', ->
        [pack, worker] = [null, null]
        before (done) ->
          pack = unidiff.find (file) ->
            file.name is "package.json"
          worker = unidiff.find (file) ->
            file.name is "worker.js"
          done()

        it "should include file names", (done) ->
          unidiff.map('name').sort().should.eql ['package.json', 'worker.js']
          done()

        describe "ranges", ->
          it "should exist", (done) ->
            should.exist pack.ranges
            should.exist worker.ranges
            pack.ranges.length.should.eql 1
            worker.ranges.length.should.eql 2
            done()

          it "should include 'removed' and 'added' blocks", (done) ->
            unidiff.map("ranges").flatten().each (range) ->
              should.exist range.removed
              should.exist range.added
            done()

          it "should include correct scopes in each 'removed' & 'added' block", (done) ->
            pack.ranges.first().removed.from.should.eql 19
            pack.ranges.first().removed.to.should.eql 26
            pack.ranges.first().removed.total.should.eql 7
            pack.ranges.first().added.from.should.eql 19
            pack.ranges.first().added.to.should.eql 27
            pack.ranges.first().added.total.should.eql 8
            worker.ranges.first().removed.from.should.eql 18
            worker.ranges.first().removed.to.should.eql 24
            worker.ranges.first().removed.total.should.eql 6
            worker.ranges.first().added.from.should.eql 18
            worker.ranges.first().added.to.should.eql 29
            worker.ranges.first().added.total.should.eql 11
            worker.ranges.last().removed.from.should.eql 41
            worker.ranges.last().removed.to.should.eql 47
            worker.ranges.last().removed.total.should.eql 6
            worker.ranges.last().added.from.should.eql 46
            worker.ranges.last().added.to.should.eql 54
            worker.ranges.last().added.total.should.eql 8
            done()

          it "should include original lines in a range", (done) ->
            should.exist pack.ranges.first().lines
            pack.ranges.first().lines.length.should.eql 10
            done()

          it "should include appropriate lines in 'removed' & 'added' blocks", (done) ->
            pack.ranges.first().removed.lines.length.should.eql 7
            pack.ranges.first().added.lines.length.should.eql 8
            pack.ranges.first().added.lines.map((line) ->
              line.diffindex + ":" + line.action + line.text
            ).should.eql [
              "2:   \"readmeFilename\": \"README.md\","
              "3:   \"dependencies\": {"
              "4:     \"jshint\": \"~2.5.0\","
              "6:+    \"sugar\": \"~1.4.1\","
              "7:+    \"github\": \"~0.1.16\""
              "8:   },"
              "9:   \"strider\": {"
              "10:     \"id\": \"jshint\","
            ]
            done()

