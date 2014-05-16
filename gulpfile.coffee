﻿gulp = require('gulp')
gutil = require('gulp-util')
coffee = require('gulp-coffee')

paths =
  coffee: 'app/shared/assets/app.coffee'
  static: 'static'

gulp.task 'default', ->

gulp.task 'coffee', ->
  gulp.src(paths.coffee)
    .pipe coffee(bare: true).on('error', gutil.log)
    .pipe gulp.dest(paths.static)

gulp.task 'watch', ->
  gulp.watch paths.coffee, ['coffee']

