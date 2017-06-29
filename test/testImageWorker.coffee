test        = require 'tape'
sinon       = require 'sinon'

ImageContainer = require '../src/imageContainer'
ImageResult    = require '../src/imageResult'
ImageWorker    = require '../src/imageWorker'
EmojiStore     = require '../src/emojiStore'

emojiFetchFn = (cb) ->
  cb null,
    favico: 'http://tinylittlelife.org/favicon.ico'
fakeEmojiStore = new EmojiStore(emojiFetchFn, 0)

allMacros = require '../src/defaultMacros'

# make a fake image worker that "resolves"
#   by returning the value passed here as an arg
mkResolver = (resultVal, label) ->
  do (resultVal, label) ->
    ret = new ImageWorker (label || resultVal), [], {}
    ret.resolve = (cb) ->
      setTimeout () ->
        ret.result = resultVal
        cb(resultVal)
      , Math.floor(Math.random() * 25)
    ret

# make a fake image worker that resolves both
#  a result value and its normalized args
mkFaker = (resultVal, label, normalArgs) ->
  do (resultVal, label, normalArgs) ->
    ret = new ImageWorker label, [], {}
    ret.resolve = (cb) ->
      setTimeout () ->
        ret.result = resultVal
        ret.normalArgs = normalArgs
        cb(resultVal)
      , Math.floor(Math.random() * 25)
    ret

test 'ImageWorker', (troot) ->

  test "fakeworker really works", (t) ->
    w = mkResolver(3)
    x = mkResolver(4)
    t.equal(w.result, null)
    w.resolve (result) ->
      t.equal(result, 3)
      t.equal(w.result, 3)
      t.end()

  test "mkFaker is real", (t) ->
    w = mkFaker(3, "foo", [1,2,3])
    t.equal(w.result, null)
    w.resolve (result) ->
      t.equal(result, 3)
      t.equal(w.result, 3)
      t.deepEqual(w.normalArgs, [1,2,3])
      t.end()

  test "constructs", (t) ->
    iw = new ImageWorker("a", "b", "c")
    t.equal(iw.parseDescription, "a", "parseDescription is initialized")
    t.equal(iw.args, "b", "args are initialized")
    t.equal(iw.workFn, "c", "workFn is initialized")
    t.end()

  test "creates null normal args on construct", (t) ->
    vals = [8, 6, 7, 5, 3, 0, 9]
    fakeWorkers = vals.map mkResolver
    iw = new ImageWorker("", fakeWorkers, {})
    t.equal(iw.normalArgs, null)
    t.end()

  test 'subResolves args', (t) ->
    vals = [8, 6, 7, 5, 3, 0, 9]
    fakeWorkers = vals.map mkResolver
    iw = new ImageWorker("", fakeWorkers, {})
    t.equal(iw.normalArgs, null)
    t.deepEqual(iw.args.map((x) -> x.result), vals.map(() -> null), 'no results initially')
    iw.subResolve (err, result) ->
      t.equal(err, null, 'no error on prepare')
      t.deepEqual(iw.args.map((x) -> x.result), vals, 'resolved results equal original args')
      t.false(iw.argsValid(), "resolved args aren't ImageResult objects")
      t.end()

  test 'subResolves ImageResult args', (t) ->
    ir1 = new ImageResult
    ir2 = new ImageResult
    ir1.resultImage = ir2.resultImage = "fake"
    vals = [ir1, ir2]
    fakeWorkers = vals.map mkResolver
    iw = new ImageWorker("", fakeWorkers, {})
    iw.subResolve (err, result) ->
      t.equal(err, null, 'no error on prepare')
      arg1 = iw.args[0].result
      t.equal(arg1.constructor.name, "ImageResult", "proper type")
      t.equal(arg1.isValid(), true, "valid although fake")
      t.true(iw.argsValid(), "resolved args are ImageResult objects")
      t.end()

  test 'creates error results with no extra info', (t) ->
    iw = new ImageWorker("", [], {})
    er = iw.errorResult()
    t.deepEqual(er.intermediateImages, [], "no intermediate images")
    t.deepEqual(er.errorMessages, [], "no error messages")
    t.equal(er.resultImage, null, "no result image")
    t.end()

  test 'creates error results with other messages', (t) ->
    iw = new ImageWorker("", [], {})
    extraErrs = ["a", "b"]
    er = iw.errorResult(extraErrs)
    t.deepEqual(er.intermediateImages, [], "no intermediate images")
    t.deepEqual(er.errorMessages, extraErrs, "error messages are as specified")
    t.equal(er.resultImage, null, "no result image")
    t.end()

  test 'creates error results with other images', (t) ->
    iw = new ImageWorker("", [], {})
    extraImgs = ["a", "b"]
    er = iw.errorResult([], extraImgs)
    t.deepEqual(er.intermediateImages, extraImgs, "intermediate images")
    t.deepEqual(er.errorMessages, [], "no error messages")
    t.equal(er.resultImage, null, "no result image")
    t.end()

  test 'creates error results with everything', (t) ->
    ir1 = new ImageResult(["A", "B"], [1, 2, 3], "C")
    ir2 = new ImageResult(["D", "E"], [4, 5, 6], "F")
    ir3 = new ImageResult(["g", "h"], [7, 8, 9], "i")
    ir4 = new ImageResult(["j", "k"], [10, 11, 12], "l")
    fakeWorkers = [mkResolver(ir1, "ir1"), mkFaker(ir2, "ir2", [ir3, ir4, {}])]
    iw = new ImageWorker("zyx", fakeWorkers, {})
    t.deepEqual(iw.cumulativeTempImages(), [])
    t.equal(iw.args[0].parseDescription, "ir1")
    iw.subResolve (err, result) ->
      t.deepEqual(iw.cumulativeTempImages().sort(), ["A", "B", "C", "D", "E", "F", "g", "h", "i", "j", "k", "l"])

      extraImgs = ["aa", "bb"]
      extraErrs = [22, 33]
      er = iw.errorResult(extraErrs, extraImgs)
      t.deepEqual(er.intermediateImages.sort(),
        ["A", "B", "C", "D", "E", "F", "g", "h", "i", "j", "k", "l", "aa", "bb"].sort(),
        "intermediate images")
      t.deepEqual(er.allTempImages().sort(),
        ["A", "B", "C", "D", "E", "F", "g", "h", "i", "j", "k", "l", "aa", "bb"].sort(),
        "intermediate images")
      t.deepEqual(er.errorMessages, [1, 2, 3, 4, 5, 6, 22, 33], "no error messages")
      t.equal(er.resultImage, null, "no result image")
      t.end()

  test 'checks successful subResolve of ImageResult args', (t) ->
    ir1 = new ImageResult
    ir1.resultImage = "fake"
    vals = [ir1]
    fakeWorkers = vals.map mkResolver
    iw = new ImageWorker("", fakeWorkers, {})
    iw.subResolve (err, result) ->
      iw.checkSubResolve (err) ->
        t.false(err, 'no error on subresolve')
        t.end()

  test 'checks good resolved args', (t) ->
    ir1 = new ImageResult
    ir2 = new ImageResult
    ir1.resultImage = ir2.resultImage = "fake"
    vals = [ir1, ir2]
    fakeWorkers = [mkResolver(ir1, ":ir1:"), mkResolver(ir2, ":ir2:")]
    iw = new ImageWorker("", fakeWorkers, {})
    iw.resolvedArgs = vals
    iw.subResolve (err, result) ->
      iw.checkResolvedArgs (err) ->
        t.false(err, "no error for good args")
        t.end()

  test 'checks bad resolved args', (t) ->
    ir1 = new ImageResult
    ir2 = {}
    ir1.resultImage = "fake"
    vals = [ir1, ir2]
    fakeWorkers = vals.map mkResolver
    iw = new ImageWorker("", fakeWorkers, {})
    iw.resolvedArgs = vals
    iw.subResolve (err, result) ->
      iw.checkResolvedArgs (err) ->
        t.true(err instanceof ImageResult)
        t.deepEqual(err.errorMessages, ["1 didn't resolve to an ImageResult, got Object"])
        t.end()

  test 'checks invalid resolved args', (t) ->
    ir1 = new ImageResult
    ir2 = new ImageResult
    ir1.resultImage = "fake"
    ir2.resultImage = null
    vals = [ir1, ir2]
    fakeWorkers = vals.map mkResolver
    iw = new ImageWorker("", fakeWorkers, {})
    iw.resolvedArgs = vals
    iw.subResolve (err, result) ->
      iw.checkResolvedArgs (err) ->
        t.true(err instanceof ImageResult)
        t.deepEqual(err.errorMessages, ["1 didn't produce a valid ImageResult"])
        t.end()

  doWorkFnTest = (testTitle, sampleResult, doChecks) ->
    test testTitle, (t) ->
      ir1 = new ImageResult
      ir1.resultImage = "fake"
      iw = new ImageWorker "myParseDesc", [], (args, cb) ->
        cb(sampleResult)
      iw.normalArgs = [ir1]
      iw.workFnWrapper (err, result) ->
        imgResult = if err instanceof ImageResult then err else result
        t.true(imgResult instanceof ImageResult, "wrapper produces ImageResult one way or the other")
        doChecks(t, err, result)
        t.end()

  doWorkFnTest "Wraps workFn all-null returns", null, (t, err, result) ->
    t.true(err instanceof ImageResult, "wrapper produces err ImageResult")
    t.equal(result, null, "wrapper produces result null")
    t.equal(null, err.resultImage, "no result image in err")
    t.deepEqual(err.intermediateImages, ["fake"])
    t.deepEqual(err.errorMessages, ["'myParseDesc' workFn error: result is null"])

  doWorkFnTest "Wraps workFn incorrect return type", "shucks", (t, err, result) ->
    t.true(err instanceof ImageResult, "wrapper produces err ImageResult")
    t.equal(result, null, "wrapper produces result null")
    t.equal(null, err.resultImage, "no result image in err")
    t.deepEqual(err.intermediateImages, ["fake"])
    t.deepEqual(err.errorMessages, ["'myParseDesc' workFn error: result not ImageResult"])

  doWorkFnTest "Wraps workFn invalid result", (new ImageResult ["fake2"]), (t, err, result) ->
    t.true(err instanceof ImageResult, "wrapper produces err ImageResult")
    t.equal(result, null, "wrapper produces result null")
    t.equal(null, err.resultImage, "no result image in err")
    t.deepEqual(err.intermediateImages.sort(), ["fake", "fake2"].sort())
    t.deepEqual(err.errorMessages, ["'myParseDesc' workFn error: ImageResult not valid"])

  doWorkFnTest "Wraps workFn no-error valid ImageResult", (new ImageResult ["fake2"], [], "fake3"), (t, err, result) ->
    t.equal(err, null, "wrapper produces err null")
    t.true(result instanceof ImageResult, "wrapper produces result ImageResult")
    t.deepEqual(result.allTempImages().sort(), ["fake2", "fake3"].sort())
    t.deepEqual(result.intermediateImages.sort(), ["fake2"].sort())
    t.equal(result.resultImage, "fake3")
    t.deepEqual(result.errorMessages, [])

  test "Full resolution and tempImage collection of emoji", (t) ->
    ImageContainer.clearContainerTracker()
    iw = new ImageWorker ":favico:", [], fakeEmojiStore.workFn("favico")
    iw.resolve (result) ->
      t.equal(result.provenance().length, 1)
      result.cleanup()
      t.deepEqual(value for own _, value of ImageContainer.activeContainers(), [])
      t.end()

  test "Full resolution and tempImage collection of wrapped emoji", (t) ->
    ImageContainer.clearContainerTracker()
    iwc = new ImageWorker ":favico:", [], fakeEmojiStore.workFn("favico")
    iwp = new ImageWorker "identity_gm(:favico:)", [iwc], allMacros.identity_gm

    iwp.resolve (result) ->
      t.ok(iwc.result, "child result exists")
      t.ok(iwp.args[0].result, "child result accessible by parent")
      t.ok(iwp.normalArgs, "normalArgs exists")
      t.equal(iwp.args[0].result.provenance().length, 1)
      t.equal(iwc.result.provenance().length, 1)
      childProv = iwc.result.provenance()[0]
      t.deepEqual(iwc.result.provenance(), iwp.args[0].result.provenance())
      t.notEqual(iwp.normalArgs[0].provenance().indexOf(childProv), -1, "child tempImage is in parent resolvedArg")
      t.notEqual(iwp.result.provenance().indexOf(childProv), -1, "child tempImage is in parent result")
      result.cleanup()
      t.deepEqual(value for own _, value of ImageContainer.activeContainers(), [])
      t.end()

  troot.end()
