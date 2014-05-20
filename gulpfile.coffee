gulp = require('gulp')
gutil = require('gulp-util')
coffee = require('gulp-coffee')
notify = require("gulp-notify")
jade = require('gulp-jade')
mocha = require('gulp-mocha')
exit = require('gulp-exit')

paths =
  coffee: 'app/shared/assets/*.coffee'
  static: 'static'
  spec: ['app/**/specs/*_spec.coffee', 'app/**/specs/**/*_spec.coffee']
  sources: ['*.coffee', 'app/**/*.coffee',]
  sloc: ['*.coffee', 'app/**/*.coffee', 'app/**/*.jade']

gulp.task 'default', ->

gulp.task 'coffee', ->
  gulp.src(paths.coffee)
    .pipe coffee(bare: true).on('error', gutil.log)
    .pipe gulp.dest(paths.static)
    .pipe(notify("Compiled: <%= file.relative %>!"))

# TESTS = app/ app/**/specs/*_spec.coffee app/**/specs/**/*_spec.coffee
gulp.task 'test', ->
  return gulp.src(paths.spec)
    .pipe(mocha({
      ui: 'bdd'
      growl: true
      useColors: true
      useInlineDiffs: true
      reporter: 'list'
      compilers: 'coffee:coffee-script/register' }))
    .pipe(exit())

gulp.task 'watch', ->
  gulp.watch paths.coffee, ['coffee']
  gulp.watch paths.spec, ['test']

gulp.task 'size', ->
  size = require('gulp-size')
  gulp.src(paths.sources)
    .pipe(size({ showFiles: true }))

gulp.task 'start_cover', (cb) ->
  istanbul = require("gulp-istanbul")
  gulp.src(paths.sources)
    .pipe(istanbul())
    .on('end', cb)

gulp.task 'cover', ->
  mocha = require("gulp-mocha")
  istanbul = require("gulp-istanbul")
 
  gulp.run 'start_cover', ->
    gulp.src(testSources)
      .pipe(mocha())
      .pipe(istanbul.writeReports())


gulp.task 'sloc', ->
  sloc = require('gulp-sloc')
 
  gulp.src(paths.sloc)
    .pipe(sloc())

