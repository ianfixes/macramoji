
test        = require 'tape'
sinon       = require 'sinon'
Extensimoji = require '../src/'

ImageResult = require '../src/imageResult'
ImageWorker = require '../src/imageWorker'


# make a fake image worker that "resolves"
#   by returning the value passed here as an arg
mkResolver = (val) ->
  ret = {}
  ret.resolve = (cb) ->
    setTimeout (() -> cb(val)),
      Math.floor(Math.random() * 25)
  ret

test 'ImageWorker', (troot) ->
  test "constructs", (t) ->
    iw = new ImageWorker("a", "b", "c")
    t.equal(iw.parseDescription, "a", "parseDescription is initialized")
    t.equal(iw.args, "b", "args are initialized")
    t.equal(iw.workFn, "c", "workFn is initialized")
    t.end()

  test "creates resolved args on construct", (t) ->
    vals = [8, 6, 7, 5, 3, 0, 9]
    fakeWorkers = vals.map (x) -> mkResolver(x)
    iw = new ImageWorker("", fakeWorkers, {})
    t.equal(iw.resolvedArgs.length, vals.length, 'proper resolvedArgs size')
    t.end()

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

  test 'creates error results with no extra info', (t) ->
    iw = new ImageWorker("", [1,2,3], {})
    er = iw.errorResult()
    t.deepEqual(er.intermediateImages, [], "no intermediate images")
    t.deepEqual(er.errorMessages, [], "no error messages")
    t.equal(er.resultImage, null, "no result image")
    t.end()

  test 'creates error results with other messages', (t) ->
    iw = new ImageWorker("", [1,2,3], {})
    extraErrs = ["a", "b"]
    er = iw.errorResult(extraErrs)
    t.deepEqual(er.intermediateImages, [], "no intermediate images")
    t.deepEqual(er.errorMessages, extraErrs, "error messages are as specified")
    t.equal(er.resultImage, null, "no result image")
    t.end()

  test 'creates error results with other images', (t) ->
    iw = new ImageWorker("", [1,2,3], {})
    extraImgs = ["a", "b"]
    er = iw.errorResult([], extraImgs)
    t.deepEqual(er.intermediateImages, extraImgs, "intermediate images")
    t.deepEqual(er.errorMessages, [], "no error messages")
    t.equal(er.resultImage, null, "no result image")
    t.end()

  test 'creates error results with everything', (t) ->
    ir1 = new ImageResult(["a", "b"], [1, 2, 3], "c")
    ir2 = new ImageResult(["d", "e"], [4, 5, 6], "f")
    iw = new ImageWorker("", [100, 200], {})
    extraImgs = ["aa", "bb"]
    extraErrs = [11, 22]
    iw.resolvedArgs = [ir1, ir2, {}]
    er = iw.errorResult(extraErrs, extraImgs)
    t.deepEqual(er.intermediateImages, ["a", "b", "c", "d", "e", "f", "aa", "bb"], "intermediate images")
    t.deepEqual(er.errorMessages, [1, 2, 3, 4, 5, 6, 11, 22], "no error messages")
    t.equal(er.resultImage, null, "no result image")
    t.end()

  test 'checks successful subResolve of ImageResult args', (t) ->
    ir1 = new ImageResult
    ir1.resultImage = "fake"
    vals = [ir1]
    fakeWorkers = vals.map (x) -> mkResolver(x)
    iw = new ImageWorker("", fakeWorkers, {})
    iw.checkSubResolve (err) ->
      t.false(err, 'no error on subresolve')
      t.end()

  test 'checks good resolved args', (t) ->
    ir1 = new ImageResult
    ir2 = new ImageResult
    ir1.resultImage = ir2.resultImage = "fake"
    vals = [ir1, ir2]
    fakeWorkers = vals.map (x) -> mkResolver(x)
    iw = new ImageWorker("", fakeWorkers, {})
    iw.resolvedArgs = vals
    iw.checkResolvedArgs (err) ->
      t.false(err, "no error for good args")
      t.end()

  test 'checks bad resolved args', (t) ->
    ir1 = new ImageResult
    ir2 = {}
    ir1.resultImage = "fake"
    vals = [ir1, ir2]
    fakeWorkers = vals.map (x) -> mkResolver(x)
    iw = new ImageWorker("", fakeWorkers, {})
    iw.resolvedArgs = vals
    iw.checkResolvedArgs (err) ->
      t.true(err instanceof ImageResult)
      t.end()

  doWorkFnTest = (testTitle, sampleResult, doChecks) ->
    test testTitle, (t) ->
      ir1 = new ImageResult
      ir1.resultImage = "fake"
      iw = new ImageWorker "myParseDesc", [1], (args, cb) ->
        cb(sampleResult)
      iw.resolvedArgs = [ir1]
      iw.workFnWrapper (err, result) ->
        t.true(err instanceof ImageResult || result instanceof ImageResult, "wrapper produces ImageResult one way or the other")
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
    t.deepEqual(err.intermediateImages, ["fake", "fake2"])
    t.deepEqual(err.errorMessages, ["'myParseDesc' workFn error: ImageResult not valid"])

  doWorkFnTest "Wraps workFn no-error valid ImageResult", (new ImageResult ["fake2"], [], "fake3"), (t, err, result) ->
    t.equal(err, null, "wrapper produces err null")
    t.true(result instanceof ImageResult, "wrapper produces result ImageResult")
    t.deepEqual(result.allTempImages(), ["fake2", "fake", "fake3"])
    t.deepEqual(result.intermediateImages, ["fake2", "fake"])
    t.deepEqual(result.resultImage, "fake3")
    t.deepEqual(result.errorMessages, [])

  troot.end()

