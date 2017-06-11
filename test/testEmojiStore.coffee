test        = require 'tape'
sinon       = require 'sinon'
fs          = require 'fs'
Extensimoji = require '../src/'

ImageResult = require '../src/imageResult'
ImageWorker = require '../src/imageWorker'
EmojiStore = require '../src/emojiStore'

test 'Emoji Store', (troot) ->
  test 'can download, run stats, and cleanup', (t) ->
    es = new EmojiStore
    es.store =
      favico: 'http://tinylittlelife.org/favicon.ico'

    doTheThing = es.workFn("favico")
    doTheThing [], (result) ->
      t.true(fs.existsSync(result.imgPath()), 'the temp image should exist')
      t.equal(result.size(), 43, 'we downloaded what we expected')
      result.dimensions (err, dims) ->
        t.fail(err, 'getting dimensions succeeds') if err
        t.deepEqual(dims, {height: 1, width: 1})
        result.normalDimension (err, dim) ->
          t.fail(err, 'getting normal dimension succeeds') if err
          t.equal(dim, 1, 'dimension is 1')
          result.cleanup()
          t.false(fs.existsSync(result.imgPath()), 'image should be deleted')
          t.end()
  troot.end()
