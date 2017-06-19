test  = require 'tape'
sinon = require 'sinon'
fs    = require 'fs'

ImageResult = require '../src/imageResult'
ImageWorker = require '../src/imageWorker'
EmojiStore  = require '../src/emojiStore'

fakeClient =
  emoji:
    list: (cb) ->
      cb null,
        emoji:
          favico: 'http://tinylittlelife.org/favicon.ico'

test 'Emoji Store', (troot) ->
  test 'can initialize emoji store with fake client', (t) ->
    es = new EmojiStore(fakeClient, 0)
    t.deepEqual(es.urls,
      favico: 'http://tinylittlelife.org/favicon.ico')
    t.true(es.hasEmoji("favico"))
    t.end()

  test 'builtins work', (t) ->
    es = new EmojiStore(fakeClient, 0)
    t.ok(es.hasEmoji("copyright"), "emoji has :copyright:")
    t.end()

  test 'can download, run stats, and cleanup', (t) ->
    es = new EmojiStore(fakeClient, 0)

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
