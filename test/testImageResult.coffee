
test        = require 'tape'
sinon       = require 'sinon'
Extensimoji = require '../src/'

ImageResult = require '../src/imageResult'

test 'ImageResult', (troot) ->
  test 'initializes its args', (t) ->
    ir1 = new ImageResult
    t.deepEqual(ir1.tempImages, [], "tempImages initialized empty")
    t.deepEqual(ir1.errorMessages, [], "errorMessages initialized empty")
    t.deepEqual(ir1.resultImage, null, "resultImage is null")
    t.end()

  test 'handles results', (t) ->
    ir1 = new ImageResult
    t.equal(ir1.resultImage, null, "resultImage starts null")
    t.false(ir1.isValid(), "null images aren't valid")
    ir1.addResult "foo", () ->
      0
    t.true(ir1.isValid(), "non-null images are valid")
    t.end()

  test 'does cleanup', (t) ->
    ir1 = new ImageResult
    ir1.addResult "foo", () ->
      t.end()
    ir1.cleanup()

  test 'creates temp images', (t) ->
    ir1 = new ImageResult
    t.equal(ir1.imgPath(), null)
    ir1.createTempImage (err, result) ->
      t.equal(err, null, "no error on create")
      t.false(ir1.isValid(), "created image isn't ir1")
      t.notEqual(result.path, null)
      t.deepEqual(ir1.tempImages, [])
      t.end()

  test 'adds temp images', (t) ->
    ir1 = new ImageResult
    t.equal(ir1.imgPath(), null)
    ir1.addTempImage (err, newPath) ->
      t.equal(err, null, "no error on create")
      t.notEqual(newPath, null)
      t.equal(ir1.tempImages.length, 1)
      t.equal(ir1.tempImages[0].path, newPath)
      t.equal(ir1.resultImage, null)
      t.deepEqual(ir1.allTempImages(), ir1.tempImages)
      t.end()

  test 'adds result images', (t) ->
    ir1 = new ImageResult
    t.equal(ir1.imgPath(), null)
    ir1.addResultImage (err, newPath) ->
      t.equal(err, null, "no error on create")
      t.notEqual(newPath, null)
      t.equal(ir1.tempImages.length, 0)
      t.equal(ir1.resultImage.path, newPath)
      t.deepEqual(ir1.allTempImages(), [ir1.resultImage])
     t.end()

  troot.end()

