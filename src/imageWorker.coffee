ImageResult = require '../src/'

http = require 'http'
fs = require 'fs'

download = (url, dest, cb) ->
  file = fs.createWriteStream(dest)
  request = http.get(url, (response) ->
    response.pipe(file)
    file.on 'finish', () ->
      file.close(cb);  # close() is async, call cb after close completes.
  ).on('error', (err) -> # Handle errors
    # fs.unlink dest  # Delete the file async. (But we don't check the result)
    cb(err.message) if (cb)
  )

# TODO: if bubbling up an error, we should make a call stack
class ImageWorker
  # workFn will have to contain a callback that expects an imageResult
  constructor: (@children, @args, @workFn) ->
    @result = null

  # callback takes imageResult
  resolve: (callback) ->
    return callback(@result) if @result


module.exports = ImageWorker
