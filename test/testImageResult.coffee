
test  = require 'tape'
sinon = require 'sinon'

ImageResult    = require '../src/imageResult'
ImageContainer = require '../src/imageContainer'

ic1 = new ImageContainer "foo", () ->
  0
ic2 = new ImageContainer "bar", () ->
  0
test 'ImageResult', (troot) ->
  test 'initializes its args when empty', (t) ->
    ir1 = new ImageResult
    t.deepEqual(ir1.intermediateImages, [], "tempImages initialized empty")
    t.deepEqual(ir1.errorMessages, [], "errorMessages initialized empty")
    t.deepEqual(ir1.resultImage, null, "resultImage is null")
    t.end()

  test 'initializes its args when 1 specified', (t) ->
    ir1 = new ImageResult [1]
    t.deepEqual(ir1.intermediateImages, [1], "tempImages has 1")
    t.deepEqual(ir1.errorMessages, [], "errorMessages initialized empty")
    t.deepEqual(ir1.resultImage, null, "resultImage is null")
    t.end()

  test 'initializes its args when 2 specified', (t) ->
    ir1 = new ImageResult [1], [2]
    t.deepEqual(ir1.intermediateImages, [1], "tempImages has 1")
    t.deepEqual(ir1.errorMessages, [2], "errorMessages has 2")
    t.deepEqual(ir1.resultImage, null, "resultImage is null")
    t.end()

  test 'initializes its args when 3 specified', (t) ->
    ir1 = new ImageResult [1], [2], 3
    t.deepEqual(ir1.intermediateImages, [1], "tempImages has 1")
    t.deepEqual(ir1.errorMessages, [2], "errorMessages has 2")
    t.deepEqual(ir1.resultImage, 3, "resultImage is 3")
    t.end()

  test 'handles results', (t) ->
    ir1 = new ImageResult
    t.equal(ir1.resultImage, null, "resultImage starts null")
    t.false(ir1.isValid(), "null images aren't valid")
    ir1.addResult(ic1)
    t.true(ir1.isValid(), "non-null images are valid")
    t.equal(ir1.imgPath(), "foo")
    t.equal(ir1.intermediateImages.length, 0, "result image not in temp array")
    ir1.addResult(ic2)
    t.true(ir1.isValid(), "another image is valid too")
    t.equal(ir1.intermediateImages.length, 1, "old result now temp")
    t.equal(ir1.intermediateImages[0].path, "foo", "old result matches temp[0]")
    t.end()

  test 'does cleanup', (t) ->
    ic3 = new ImageContainer "foo", () ->
      t.end()

    ir1 = new ImageResult
    ir1.addResult ic3
    ir1.cleanup()

  troot.end()

