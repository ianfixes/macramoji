test  = require 'tape'
sinon = require 'sinon'

ImageContainer = require '../src/imageContainer'

test 'ImageContainer', (troot) ->
  test 'initializes its args', (t) ->
    ic1 = new ImageContainer "foo", () ->
      0
    t.equal(ic1.path, "foo", "image container path works")
    t.equal(typeof ic1.cleanupCallback, "function", "cleanup is function")

    ic2 = new ImageContainer "bar", null
    t.equal(ic2.path, "bar", "image container path 2 works")
    t.equal(ic2.cleanupCallback, null, "cleanup is null")
    t.end()

  test 'static init', (t) ->
    ImageContainer.fromNewTempFile (err, ic1) ->
      t.equal(err, null, "image container creation didn't error")
      t.notEqual(ic1.path, null, "image container path works")
      t.equal(typeof ic1.cleanupCallback, "function", "cleanup is function")
      t.end()

  test "idempotent cleanup", (t) ->
    count = 0
    ic1 = new ImageContainer "foo", () ->
      count = count + 1
    t.equal(count, 0, "cleanup callback hasn't been called")
    ic1.cleanup()
    t.equal(count, 1, "cleanup callback has been called")
    ic1.cleanup()
    t.equal(count, 1, "cleanup callback hasn't been called twice")
    t.end()

  test "track number of containers", (t) ->
    baseCount = ImageContainer.existingContainerCount()
    ImageContainer.fromNewTempFile (err, ic1) ->
      t.equal(ImageContainer.existingContainerCount(), baseCount + 1)
      ic1.cleanup()
      t.equal(ImageContainer.existingContainerCount(), baseCount)
      ic1.cleanup()
      t.equal(ImageContainer.existingContainerCount(), baseCount)
      t.end()

  troot.end()
