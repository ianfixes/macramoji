
test        = require 'tape'
sinon       = require 'sinon'
Extensimoji = require '../src/'

ImageResult = require '../src/imageResult'
ImageWorker = require '../src/imageWorker'

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

# TODO: this will eventually be part of the emoji store
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
  # test 'can download, run stats, and cleanup', (t) ->
  #   favico = 'http://tinylittlelife.org/favicon.ico'
  #   doTheThing = makeWorkFn(favico)
  #   doTheThing [], (result) ->
  #     t.true(fs.existsSync(result.imgPath()), 'the temp image should exist')
  #     t.equal(result.size(), 43, 'we downloaded what we expected')
  #     result.dimensions (err, dims) ->
  #       t.fail(err, 'getting dimensions succeeds') if err
  #       t.deepEqual(dims, {height: 1, width: 1})
  #       result.normalDimension (err, dim) ->
  #         t.fail(err, 'getting normal dimension succeeds') if err
  #         t.equal(dim, 1, 'dimension is 1')
  #         result.cleanup()
  #         t.false(fs.existsSync(result.imgPath()), 'image should be deleted')
  #         t.end()
  troot.end()

mkResolver = (val) ->
  ret = {}
  ret.resolve = (cb) ->
    setTimeout (() -> cb(val)),
      Math.floor(Math.random() * 25)
  ret

test 'ImageWorker', (troot) ->
  test 'subResolves args', (t) ->
    vals = [8, 6, 7, 5, 3, 0, 9]
    fakeWorkers = vals.map (x) -> mkResolver(x)
    iw = new ImageWorker("", fakeWorkers, {})
    t.equal(iw.resolvedArgs.length, vals.length, 'proper resolvedArgs size')
    t.deepEqual(iw.resolvedArgs, Array(vals.length).fill(null), 'initally null')
    iw.subResolve (err, result) ->
      t.equal(err, null, 'no error on prepare')
      t.deepEqual(iw.resolvedArgs, vals, 'resolved args equal original args')
      t.false(iw.argsValid(), "resolved args aren't ImageResult objects")
      t.end()

  test 'subResolves ImageResult args', (t) ->
    ir1 = new ImageResult
    ir2 = new ImageResult
    ir1.resultImage = ir2.resultImage = "fake"
    vals = [ir1, ir2]
    fakeWorkers = vals.map (x) -> mkResolver(x)
    iw = new ImageWorker("", fakeWorkers, {})
    iw.subResolve (err, result) ->
      t.equal(err, null, 'no error on prepare')
      arg1 = iw.resolvedArgs[0]
      t.equal(arg1.constructor.name, "ImageResult", "proper type")
      t.equal(arg1.isValid(), true, "valid although fake")
      t.true(iw.argsValid(), "resolved args are ImageResult objects")
      t.end()

  test 'enforces work functions returning ImageResult objects', (t) ->
    t.end()

  test 'bubbles up errors in arguments instead of doing the work', (t) ->
    t.end()

  troot.end()

