
test        = require 'tape'
sinon       = require 'sinon'
Extensimoji = require '../src/'

ImageResult = require '../src/imageResult'

http = require 'http'
fs = require 'fs'
tmp = require 'tmp'

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

makeWorkFn = (url) ->
  # onComplete takes an ImageResult
  return (argsWhichAreImageResults, onComplete) ->
    tmp.file { discardDescriptor: true }, (err, path, fd, cleanupCallback) ->
      ret = new ImageResult
      if (err)
        ret.addErrors [err]
        onComplete(ret)

      download url, path, (err2, result) ->
        if (err2)
          ret.addErrors [err2]
          cleanupCallback()
          onComplete(ret)

        ret.addResult path, cleanupCallback
        onComplete(ret)

test 'WIP', (troot) ->
  test 'can download and cleanup', (t) ->
    favico = 'http://tinylittlelife.org/favicon.ico'
    doTheThing = makeWorkFn(favico)
    doTheThing [], (result) ->
      t.equal(result.size(), 43)
      t.true(fs.existsSync(result.imgPath()), 'the temp image should exist')
      result.cleanup()
      t.false(fs.existsSync(result.imgPath()), 'the temp image should be gone')
      t.end()

  test 'enforces work functions returning ImageResult objects', (t) ->
    t.end()

  test 'bubbles up errors in arguments instead of doing the work', (t) ->
    t.end()

  troot.end()

