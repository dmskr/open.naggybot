gulp = require('gulp')
gutil = require('gulp-util')
coffee = require('gulp-coffee')
notify = require("gulp-notify")
jade = require('gulp-jade')

paths =
  coffee: 'app/shared/assets/*.coffee'
  static: 'static'
  templates: 'app/repos/assets/*.jade'
  templatesDest: 'static/repos'

gulp.task 'default', ->

gulp.task 'coffee', ->
  gulp.src(paths.coffee)
    .pipe coffee(bare: true).on('error', gutil.log)
    .pipe gulp.dest(paths.static)
    .pipe(notify("Compiled: <%= file.relative %>!"))

gulp.task 'templates', ->
  gulp.src(paths.templates)
    .pipe(jade({
      locals: {}
    }))
    .pipe(gulp.dest(paths.templatesDest))
    .pipe(notify("Compiled: <%= file.relative %>!"))

gulp.task 'watch', ->
  gulp.watch paths.coffee, ['coffee']
  gulp.watch paths.templates, ['templates']

