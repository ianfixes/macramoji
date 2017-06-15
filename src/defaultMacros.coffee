fs    = require 'fs'
path  = require 'path'
gm    = require 'gm'
async = require 'async'
imageMagick = gm.subClass { imageMagick: true }

ImageContainer = require './imageContainer'
imageTransform = require './imageTransform'
ImageResult    = require './imageResult'

debug = false

# TODO: all exports in this file must act on an array of paths
# and a callback that takes (err, ImageResult)

# Test case: Output what we input
identity = (paths, onComplete) ->
  initFn = (path, cb) ->
    fs.writeFileSync(path, fs.readFileSync(paths[0]))
    cb()
  ImageResult.initFromNewTempFile initFn, onComplete

# Test case: output what we input, but use GM
identity_gm = (paths, cb) ->
  explode = path.join(__dirname, '..', 'data', 'img', 'explosion.gif')
  workFn = (inputGm) ->
    inputGm

  imageTransform.resultFromGM gm(paths[0]), workFn, cb, "gif"

# Make an explosion
splosion = (paths, cb) ->
  explode = path.join(__dirname, '..', 'data', 'img', 'explosion.gif')

  imageMagick(paths[0]).identify (err, result) ->
    # this is my best guess at how to detect animation with GM
    isAnimated = err == null \
      && result.Delay != undefined \
      && Array.isArray(result.Delay) \
      && result.Delay.length > 1

    maybeDelay = if isAnimated then [] else ["-set", "delay", "100"]

    workFn = (inputGm) ->
      # gm has functions for all of these, and it applies them in a different order
      # which is incorrect and honestly kind of infuriating.  so we manually work around.
      [
        ["-dispose", "Previous"],
        [paths[0]],
        ["-resize", "128x128"],
        ["-background", "transparent"],
        ["-gravity", "center"],
        ["-extent", "128x128"],
        ["-set", "page", "+0+0"],
        maybeDelay,
        [explode],
        ["-loop", "0"],
      ].reduce ((acc, elem) -> acc.in.apply(acc, elem)), inputGm

    imageTransform.resultFromGM imageMagick(), workFn, cb, "gif"

# Make glasses fall from the sky
dealwithit = (paths, cb) ->
  glasses = paths[1] || path.join(__dirname, '..', 'data', 'img', 'dealwithit_glasses.png')
  frames = []

  # final wrapup function
  onFramesAvailable = (err) ->
    workFn = (inputGm) ->
      # TODO: assemble all the frames.  first and last should get some longer delays
      fl = frames[0].path    # remember, array is in reverse so last frame is 0
      ff = paths[0]
      midframes = frames.slice(1, frames.length - 2)
      appendFrame = (acc, elem) ->
        acc.in.apply(acc, [elem.path])

      outputGm = inputGm.in("-dispose", "Previous").in("-delay", "100").in(ff)
      outputGm = midframes.reduceRight appendFrame, outputGm.in("-delay", "8")
      outputGm = outputGm.in("-dispose", "Previous").in("-delay", "200").in(fl)
      outputGm = outputGm.in("-loop", "0")
      console.log("onFramesAvailable: #{outputGm.args()}") if debug
      outputGm

    # final callback wrapper to put in all temp images
    addTempImages = (result) ->
      result.addTempImages(frames)
      cb(result)

    imageTransform.resultFromGM imageMagick(), workFn, addTempImages, "gif"

  # start with the size -- used to calc speed and offset
  gm(paths[0]).size (err, size) ->
    # TODO: something with err
    maxDim = if size.width > size.height then size.width else size.height
    offset = 0
    increment = 4 #Math.max(1, Math.ceil(maxDim / 32))

    # truth function for the async.during call
    notTooHigh = (callback) ->
      return callback(null, true) if frames.length < 2
      return callback(null, false) if offset > maxDim
      # when 2 images are not equal, we are not too high with the glasses.
      # when glasses go out of frame, the 2 images WILL be equal
      f1 = frames[frames.length - 1].path
      f2 = frames[frames.length - 2].path
      gm.compare f1, f2, 0, (err, isEqual, equality, raw) ->
        console.log("GM err #{err}") if err && debug
        callback(err, !isEqual)

    # iteration function for the async.during call
    generateFrame = (callback) ->
      # start with a temp image
      ImageContainer.fromNewTempFile (err, imgContainer) ->
        return callback(err) if err
        frames.push(imgContainer)

        temp = [
          ["-size", "#{maxDim}x#{maxDim}"],
          ["-background", "none"],
          ["-page", "+0+0", paths[0]],
          #["-page", "-0-#{offset}", glasses]
          ["-page", "-0-#{offset}", "\(", glasses, "-resize", "#{maxDim}x#{maxDim}", "\)"]
          ["-layers", "flatten"],
        ].reduce ((acc, elem) -> acc.in.apply(acc, elem)), imageMagick()

        offset = offset + increment
        console.log("generateFrame: #{temp.args()}") if debug
        temp.write imgContainer.path, (err, result) ->
          console.log("GM err #{err}") if err && debug
          callback(err, result)

    async.during notTooHigh, generateFrame, onFramesAvailable


module.exports =
  identity: identity
  identity_gm: identity_gm
  splosion: splosion
  dealwithit: dealwithit
