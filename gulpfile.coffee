gulp = require('gulp')
gutil = require('gulp-util')
coffee = require('gulp-coffee')

gulp.task 'default', ->

gulp.task 'coffee', ->
  gulp.src('app/shared/assets/app.coffee')
    .pipe coffee(bare: true).on('error', gutil.log)
    .pipe gulp.dest('./static/')

