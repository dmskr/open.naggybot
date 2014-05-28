#curl -H "Accept: application/vnd.github.diff" https://api.github.com/repos/toptechphoto/picsio/pulls/1604?access_token=5ad2877558de4f48282b1edc95b28cf99a86c90fB
request = require 'request'
fs = require 'fs'
http = require("http")
tmp = require 'tmp'

url = 'https://api.github.com/repos/toptechphoto/picsio/tarball/308683ff4387c1fda7a0bce5607642e057f9193a?access_token=5ad2877558de4f48282b1edc95b28cf99a86c90f'
dest = 'ar.tar'



file = fs.createWriteStream(dest)

request(url: url, headers: { 'user-agent': 'request'}).pipe(file).on 'finish', ->
  console.log 'Finished!'

