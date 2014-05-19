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

gulp.task 'default', ->

gulp.task 'coffee', ->
  gulp.src(paths.coffee)
    .pipe coffee(bare: true).on('error', gutil.log)
    .pipe gulp.dest(paths.static)
    .pipe(notify("Compiled: <%= file.relative %>!"))

# TESTS = app/ app/**/specs/*_spec.coffee app/**/specs/**/*_spec.coffee
gulp.task 'test', ->
  return gulp.src(['app/**/specs/*_spec.coffee', 'app/**/specs/**/*_spec.coffee'])
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

