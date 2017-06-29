test  = require 'tape'
sinon = require 'sinon'
path  = require 'path'

gm = require 'gm'
imageMagick = gm.subClass { imageMagick: true }

imageTransform = require '../src/imageTransform'
ImageContainer = require '../src/imageContainer'
ImageResult    = require '../src/imageResult'
ImageWorker    = require '../src/imageWorker'
EmojiStore     = require '../src/emojiStore'

emojiFetchFn = (cb) ->
  cb null,
    favico: 'http://tinylittlelife.org/favicon.ico'
fakeEmojiStore = new EmojiStore(emojiFetchFn, 0)

allMacros = require '../src/defaultMacros'

poop = path.join(__dirname, 'img', 'dancingpoop.gif')

test 'ImageTransform', (troot) ->
  test "resultFromGM", (t) ->
    ImageContainer.clearContainerTracker()
    imageTransform.resultFromGM imageMagick(poop), ((x) -> x), (result) ->
      t.ok(result)
      t.true(result instanceof ImageResult, "result is ImageResult")
      result.cleanup()
      t.deepEqual(value for own _, value of ImageContainer.activeContainers(), [])
      t.end()

  test "normalize", (t) ->
    ImageContainer.clearContainerTracker()
    imageTransform.resultFromGM imageMagick(poop), ((x) -> x), (poopResult) ->
      t.true(poopResult instanceof ImageResult, "poopResult is ImageResult")
      t.equal(poopResult.constructor.name, "ImageResult", "poopResult is ImageResult")
      imageTransform.normalize poopResult, 16, (result) ->
        t.ok(result, "result is not false")
        t.ok(result.constructor, "result has constructor")
        t.equal(result.constructor.name, "ImageResult", "result is ImageResult")
        result.cleanup()
        t.deepEqual(value for own _, value of ImageContainer.activeContainers(), [])
        t.end()

  troot.end()
