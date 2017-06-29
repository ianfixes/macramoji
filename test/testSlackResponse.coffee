test  = require 'tape'
sinon = require 'sinon'

ImageContainer = require '../src/imageContainer'
ImageResult = require '../src/imageResult'
SlackResponse = require '../src/slackResponse'

test 'SlackResponse', (troot) ->
  test 'initializes its args', (t) ->
    sr = new SlackResponse
    t.equal(sr.message, null)
    t.equal(sr.imgResult, null)
    t.equal(sr.fileDesc, null)
    t.end()

  test "full stack cleanup of results is idempotent", (t) ->
    count = 0
    ic1 = new ImageContainer "foo", () ->
      count = count + 1
    ir1 = new ImageResult([], [], ic1)
    sr1 = new SlackResponse
    sr1.imgResult = ir1
    t.equal(count, 0, "cleanup callback hasn't been called")
    sr1.cleanup()
    t.equal(count, 1, "cleanup callback has been called")
    sr1.cleanup()
    t.equal(count, 1, "cleanup callback hasn't been called twice")
    t.end()

  test "full stack cleanup of temp images idempotent", (t) ->
    count = 0
    ic1 = new ImageContainer "foo", () ->
      count = count + 1
    ir1 = new ImageResult([ic1], [], null)
    sr1 = new SlackResponse
    sr1.imgResult = ir1
    t.equal(count, 0, "cleanup callback hasn't been called")
    sr1.cleanup()
    t.equal(count, 1, "cleanup callback has been called")
    sr1.cleanup()
    t.equal(count, 1, "cleanup callback hasn't been called twice")
    t.end()


  troot.end()
