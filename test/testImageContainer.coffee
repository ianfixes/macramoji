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

  troot.end()
