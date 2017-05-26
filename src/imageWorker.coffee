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

  errorMessages: () ->
    if @result? then [] else @result.errorMessages

  tempImages: () ->
    if @result? then [] else @result.tempImages

  # tally up the error messages from all args
  errorResult: (otherMessages) ->
    tempImages = []
    errorMessages = []
    for a in @resolvedArgs
      if a?
        tempImages = tempImages.concat(a.tempImages)
        errorMessages = errorMessages.concat(a.errorMessages)
    errorMessages = errorMessages.concat(otherMessages) if otherMessages

    ImageResult.new tempImages, errorMessages, null

  argsValid: () ->
    @resolvedArgs.every (x) ->
      (x instanceof ImageResult) && x.isValid()

  # try to resolve all the arguments, which should produce ImageResults
  # errors here are async errors of some kind
  checkSubResolve: (cb) ->
    subResolve (err) =>
      if (err)
        cb errorResult("#{@parseDescription} subResolve error: #{err}")
      else
        cb()

  # check that all resolvedArgs contain images
  # if any args were invalid, bubble up all those error messages
  checkResolvedArgs: (cb) ->
    if !@argsValid()
      cb errorResult()
    else
      cb()

  # wrapper for normalization
  # callback takes (err)
  normalizeArgs: (dimensions, callback) ->
    dimension = Math.min(dimensions)
    work = (ir, cb) -> transform.normalize(ir, dimension, cb)
    async.map @resolvedArgs, work, (err, results) =>
      if err
        errRet = errorResult("#{@parseDescription} normalizeArgs error: #{err}")
        return callback(errRet)
      @resolvedArgs = results
      callback()

  # callback takes imageResult.  only imageresults may be returned.
  resolve: (callback) ->
    return callback(@result) if @result

    # find all normalized (max dimension) image sizes
    getNormalDims = (cb) =>
      dimFns = @resolvedArgs.map (x) -> x.normalDimension
      async.parallel dimFns, (err, result) =>
        if err
          cb errorResult("#{@parseDescription} getNormalDims error: #{err}")
        else
          cb()

    # we're going to use this in an odd way.  the outer function returns only
    # ImageResults.  So any errors are basically just early exits.
    async.waterfall([
      @checkSubResolve,
      @checkResolvedArgs,
      getNormalDimensions,
      # normalize to min of max dimension
      @normalizeArgs,



    ],
      # final result handler: err for early exit, result for success
      (err, result) ->
        if err
          @result = err
        else
          @result = result
        callback(@result)
      # run the @workFn
      # make sure the result is an ImageResult (dev error)
      # make sure that the image is not oversized (over limit)
      # if the work function results in an error,
      # annotate that with @parseDescription and finish
      # else, return the result
    )


module.exports = ImageWorker
