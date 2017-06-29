ImageResult = require './imageResult'

http = require 'http'
fs = require 'fs'
async = require 'async'
transform = require './imageTransform'

# TODO: if bubbling up an error, we should make a call stack
class ImageWorker
  # workFn will have to contain a callback that expects an imageResult
  constructor: (@parseDescription, @args, @workFn) ->
    # args are ImageWorker objects
    # normalArgs are ImageResult objects
    @result = null
    @normalArgs = null

  # callback takes err
  subResolve: (callback) =>
    async.eachOf @args, ((v, i, cb) ->
      return cb() if v.result?
      v.resolve (result) ->
        cb()
    ), callback

  # pull in all temp images from all args
  cumulativeTempImages: () =>
    ret = []
    for a in @args
      ret = ret.concat(a.cumulativeTempImages())
      if a.result instanceof ImageResult
        ret = ret.concat(a.result.allTempImages())

    if @normalArgs?
      for a in @normalArgs
        if a instanceof ImageResult
          ret = ret.concat(a.allTempImages())
    ret

  # tally up the error messages from all args
  errorResult: (otherMessages, otherImages) =>
    errorMessages = []
    for a in @args
      if a.result? && a.result instanceof ImageResult
        errorMessages = errorMessages.concat(a.result.errorMessages)
    errorMessages = errorMessages.concat(otherMessages) if otherMessages

    tempImages = @cumulativeTempImages()
    tempImages = tempImages.concat(otherImages) if otherImages

    new ImageResult tempImages, errorMessages, null
  # try to resolve all the arguments, which should produce ImageResults
  # errors here are async errors of some kind
  checkSubResolve: (cb) =>
    @subResolve (err) =>
      if (err)
        cb @errorResult(["#{@parseDescription} subResolve error: #{err}"])
      else
        cb()

  isValidImageResult: (something) ->
    (something instanceof ImageResult) && something.isValid()

  argsValid: () =>
    @args.every (x) =>
      @isValidImageResult(x.result)

  # check that all args contain images
  # if any args were invalid, bubble up all those error messages
  checkResolvedArgs: (cb) =>
    problems = []

    @args.forEach (a, i) =>
      if !(a.result instanceof ImageResult)
        aType = a.result && a.result.constructor.name
        problems.push "#{@args[i].parseDescription} didn't resolve to an ImageResult, got #{aType}"
      else if !a.result.isValid()
        problems.push "#{@args[i].parseDescription} didn't produce a valid ImageResult"

    if problems.length > 0
      cb @errorResult(problems)
    else
      cb()

  # normalize to min of max dimension, modifies @resolvedArgs in-place
  # wrapper for normalization
  # callback takes (err)
  normalizeArgs: (dimensions, callback) =>
    dimension = Math.min.apply(null, dimensions)
    # TODO: skip this if all things are already the same size

    # convert inputs and outputs for use with async.map.  transform
    #   returns an ImageResult in all cases
    normFn = (inWorker, cb) ->
      transform.normalize inWorker.result, dimension, (outResult) ->
        return cb(outResult.errorMessages.join("; ")) unless outResult.isValid()
        cb(null, outResult)

    async.map @args, normFn, (err, results) =>
      if err
        errRet = @errorResult(["'#{@parseDescription}' normalizeArgs error: #{err}"])
        return callback(errRet)
      @normalArgs = results
      callback()

  # if work fn doesn't call its callback,
  #   then we're fucked because that's the halting problem
  # if work fn has an arg problem, it has to report an error
  #   someone has to annotate that error
  # if work fn has a GM problem, it has to report an error
  #   someone has to annotate that error
  # if work fn returns a result, we have to save that result
  workFnWrapper: (callback) =>

    # if it gets an error, annotate that error
    wrappedErrResult = (definitelyErr, maybeResult) =>
      err = "'#{@parseDescription}' workFn error: #{definitelyErr}"
      if !maybeResult
        @errorResult [err]
      else if !(maybeResult instanceof ImageResult)
        @errorResult ["#{err} (and result not ImageResult)"]
      else
        @errorResult [err], maybeResult.allTempImages()

    paths = @normalArgs.map (x) -> x.imgPath()
    @workFn paths, (result) =>
      if result == null
        return callback(wrappedErrResult("result is null", null), null)
      else if !(result instanceof ImageResult)
        return callback(wrappedErrResult("result not ImageResult", null), null)
      else if !@isValidImageResult(result)
        if result.errorMessages.length == 0
          return callback(wrappedErrResult("ImageResult not valid", result), null)
        else
          return callback(wrappedErrResult("ImageResult has errors: #{result.errorMessages.join('; ')}", result), null)

      # # success; add all intermediate images from args.  wrappedErrResult would have done this otherwise
      # for a in @resolvedArgs
      #   result.addTempImages(a.allTempImages()) if a? && a instanceof ImageResult

      callback(null, result)


  # callback takes imageResult.  only imageresults may be returned.
  resolve: (callback) =>
    return callback(@result) if @result

    # find all normalized (max dimension) image sizes
    # callback returns nothing because we're overwriting in-place
    getNormalDims = (cb) =>
      dimFns = @args.map (x) -> x.result.normalDimension
      async.parallel dimFns, (err, result) =>
        if err
          cb @errorResult("'#{@parseDescription}' getNormalDims error: #{err}")
        else
          cb(null, result)

    # we're going to use this in an odd way.  the outer function returns only
    # ImageResults.  So any "errors" here are basically just early exits returning an ImageResult
    async.waterfall([
      @checkSubResolve,    # make sure args become ImageResults
      @checkResolvedArgs,  # make sure resolvedArgs contain images
      getNormalDims,       # get all image dimensions
      @normalizeArgs,      # resize all images to smallest image size
      @workFnWrapper,      # run the work function
      # TODO: this
      #@checkResultSize,    # make sure result isn't oversized
    ],
      # final result handler: err for early exit, result for success
      (err, result) =>
        if err
          @result = err
        else if result
          @result = result
        @result.addTempImages(@cumulativeTempImages())
        callback(@result)
    )


module.exports = ImageWorker
