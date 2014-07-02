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
        pack = worker = app_coffee = app_less = null
        before (done) ->
          pack = unidiff.find (file) -> file.name is "package.json"
          worker = unidiff.find (file) -> file.name is "worker.js"
          app_coffee = unidiff.find (file) -> file.name is 'app/shared/assets/app.coffee'
          app_less = unidiff.find (file) -> file.name is 'app/shared/assets/app.less'
          done()

        it "should include file names", (done) ->
          unidiff.map('name').sort().should.eql ['app/shared/assets/app.coffee', 'app/shared/assets/app.less', 'package.json', 'worker.js']
          done()

        describe "ranges", ->
          it "should exist", (done) ->
            should.exist pack.ranges
            should.exist worker.ranges
            should.exist app_coffee.ranges
            should.exist app_less.ranges
            pack.ranges.length.should.eql 1
            worker.ranges.length.should.eql 2
            app_coffee.ranges.length.should.eql 1
            app_less.ranges.length.should.eql 1
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
            app_coffee.ranges.first().removed.from.should.eql 1
            app_coffee.ranges.first().removed.to.should.eql 1
            app_coffee.ranges.first().removed.total.should.eql 0
            app_coffee.ranges.first().added.from.should.eql 1
            app_coffee.ranges.first().added.to.should.eql 19
            app_coffee.ranges.first().added.total.should.eql 18
            done()

          it "should include lines in a range", (done) ->
            should.exist pack.ranges.first().lines
            pack.ranges.first().lines.length.should.eql 10
            done()

          it "should set text field for each line", (done) ->
            pack.ranges.first().lines.map('text').each (text) ->
              should.exist text
            done()

          it "should set text field without predicating symbols", (done) ->
            pack.ranges.first().lines.map('text').each (text) ->
              if text && text.length > 0
                text[0].should.not.eql '+'
                text[0].should.not.eql '-'
            done()

          it "should set an action field for each line", (done) ->
            pack.ranges.first().lines.map('action').should.eql [null, null, null, null, '-', '+', '+', null, null, null]
            worker.ranges[1].lines.map('action').should.eql [null, null, null, null, '+', '+', null, null, null]
            done()

          it "should set uniline", (done) ->
            pack.ranges.first().lines.map('uniline').should.eql [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            worker.ranges.first().lines.map('uniline').should.eql [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            worker.ranges[1].lines.map('uniline').should.eql [13, 14, 15, 16, 17, 18, 19, 20, 21]
            done()

