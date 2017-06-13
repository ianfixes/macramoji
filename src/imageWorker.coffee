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
    # resolvedArgs are ImageResult objects
    @resolvedArgs = Array(@args.length).fill(null)
    @result = null

  # callback takes err
  subResolve: (callback) ->
    async.eachOf @resolvedArgs, ((v, i, cb) =>
      return cb() if v?
      @args[i].resolve (result) =>
        @resolvedArgs[i] = result
        cb()
    ), callback

  # tally up the error messages from all args
  errorResult: (otherMessages, otherImages) ->
    tempImages = []
    errorMessages = []
    for a in @resolvedArgs
      if a? && a instanceof ImageResult
        tempImages = tempImages.concat(a.allTempImages())
        errorMessages = errorMessages.concat(a.errorMessages)
    errorMessages = errorMessages.concat(otherMessages) if otherMessages
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

  argsValid: () ->
    @resolvedArgs.every (x) =>
      @isValidImageResult(x)

  # check that all resolvedArgs contain images
  # if any args were invalid, bubble up all those error messages
  checkResolvedArgs: (cb) =>
    problems = []

    @resolvedArgs.forEach (a, i) =>
      if !(a instanceof ImageResult)
        problems.push "#{@args[i].parseDescription} didn't resolve to an ImageResult"
      else if !a.isValid()
        problems.push "#{@args[i].parseDescription} didn't produce a valid ImageResult"

    if problems.length > 0
      cb @errorResult(problems)
    else
      cb()

  # normalize to min of max dimension, modifies @resolvedArgs in-place
  # wrapper for normalization
  # callback takes (err)
  normalizeArgs: (dimensions, callback) =>
    dimension = Math.min(dimensions)
    # TODO: skip this if all things are already the same size

    # convert inputs and outputs for use with async.map.  transform
    #   returns an ImageResult in all cases
    normFn = (inResult, cb) ->
      transform.normalize inResult, dimension, (outResult) ->
        return cb(outResult.errorMessages.join("; ")) unless outResult.isValid()
        cb(null, outResult)

    async.map @resolvedArgs, normFn, (err, results) =>
      if err
        errRet = @errorResult(["'#{@parseDescription}' normalizeArgs error: #{err}"])
        return callback(errRet)
      @resolvedArgs = results
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

    paths = @resolvedArgs.map (x) -> x.imgPath()
    @workFn paths, (result) =>
      if result == null
        return callback(wrappedErrResult("result is null", null), null)
      else if !(result instanceof ImageResult)
        return callback(wrappedErrResult("result not ImageResult", null), null)
      else if !@isValidImageResult(result)
        return callback(wrappedErrResult("ImageResult not valid", result), null)

      # success; add all intermediate images from args
      for a in @resolvedArgs
        result.addTempImages(a.allTempImages()) if a? && a instanceof ImageResult

      callback(null, result)


  # callback takes imageResult.  only imageresults may be returned.
  resolve: (callback) ->
    return callback(@result) if @result

    # find all normalized (max dimension) image sizes
    # callback returns nothing because we're overwriting in-place
    getNormalDims = (cb) =>
      dimFns = @resolvedArgs.map (x) -> x.normalDimension
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
        callback(@result)
    )


module.exports = ImageWorker
