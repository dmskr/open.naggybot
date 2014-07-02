gulp = require('gulp')
gutil = require('gulp-util')
coffee = require('gulp-coffee')
notify = require("gulp-notify")
jade = require('gulp-jade')
mocha = require('gulp-mocha')
exit = require('gulp-exit')
fs = require('fs')
async = require('async')
sugar = require('sugar')
byline = require('byline')
argv = require('yargs').argv

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

mochaoptions =
  ui: 'bdd'
  growl: true
  useColors: true
  useInlineDiffs: true
  reporter: 'list'
  compilers: 'coffee:coffee-script/register'

# TESTS = app/ app/**/specs/*_spec.coffee app/**/specs/**/*_spec.coffee
gulp.task 'test', ->
  return gulp.src(paths.spec)
    .pipe(mocha(mochaoptions))
    .pipe(exit())

gulp.task 'slowtest', ->
  return gulp.src paths.spec
    .pipe mocha(Object.merge(mochaoptions, timeout: 4000))
    .pipe exit()


gulp.task 'watch', ->
  gulp.watch paths.coffee, ['coffee']

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

  child_proc = require 'child_process'

  ssh = child_proc.spawn 'ssh', ['node@95.85.16.168']
  byline(ssh.stdout, keepEmptyLines: true).on 'data', (data) ->
    console.log(data.toString())

  byline(ssh.stderr).on 'data', (data) ->
    if data
      console.log('stderr: ' + data)

  ssh.on 'exit', (code) ->
    if code != 0
      console.log('child process exited with code ' + code)

  ["cd /var/www/naggybot"
  "git reset --hard"
  "git checkout #{argv.branch || 'master'}"
  "git pull"
  "npm install"
  "bower install"
  "gulp coffee"
  "sudo stop naggy"
  "sudo start naggy"
  "echo 'Done!'"
  "exit"].each (command) ->
    ssh.stdin.write("\n" + command + "\n")

