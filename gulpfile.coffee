gulp = require('gulp')
gutil = require('gulp-util')
coffee = require('gulp-coffee')
notify = require("gulp-notify")
jade = require('gulp-jade')
mocha = require('gulp-mocha')
exit = require('gulp-exit')
fs = require('fs')
async = require('async')

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

gulp.task 'deploy', (done) ->
  sshclient = require 'sshclient'

  opts =
    host: "95.85.16.168"
    port: 22
    debug: true # optional
    username: 'node'
    agent: process.env.SSH_AUTH_SOCK
    console: console
    directory: '/var/www/naggybot'

  sshclient.session opts, (err, ses) ->
    return console.log(err) if err
    
    commands = [
      "git reset --hard"
      "git checkout master"
      "git pull"
      "npm install"
      "bower install"
      "gulp coffee"
      "sudo stop naggy"
      "sudo start naggy"
    ].map (command) ->
      (next) -> ses.exec "cd #{opts.directory}; #{command}", (err, meta1, meta2, meta3) ->
        return next(err) if err
        next()

    async.series commands, (err) ->
      ses.quit() # need to close the session here on both error and success
      done(err)

