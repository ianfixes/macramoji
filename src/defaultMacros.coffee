fs    = require 'fs'
path  = require 'path'
gm    = require 'gm'
async = require 'async'
imageMagick = gm.subClass { imageMagick: true }

ImageContainer = require './imageContainer'
imageTransform = require './imageTransform'
ImageResult    = require './imageResult'

debug = false

getImgInfo = (inPath, cb) ->
  imageMagick(inPath).identify (err, result) ->
    # this is my best guess at how to detect animation with GM
    result.isAnimated = err == null \
      && result.Delay != undefined \
      && Array.isArray(result.Delay) \
      && result.Delay.length > 1
    cb null, result

# TODO: all exports in this file must act on an array of paths
# and a callback that takes (err, ImageResult)

# Test case: Output what we input
identity = (paths, onComplete) ->
  initFn = (path, cb) ->
    fs.writeFileSync(path, fs.readFileSync(paths[0]))
    cb()
  ImageResult.initFromNewTempFile initFn, onComplete

# Test case: output what we input, but use GM
# underscores are bad style for node, but this name is exposed to slack
identity_gm = (paths, cb) ->
  imageTransform.resultFromGM gm(paths[0]), identityWorkFn, cb, "gif"

identityWorkFn = (x) -> x

# Test case: output what we input, but use GM
firstframe = (paths, cb) ->
  imageTransform.resultFromGM imageMagick("#{paths[0]}[0]"), identityWorkFn, cb, "png"

# Test case: output what we input, but use GM
lastframe = (paths, cb) ->
  imageTransform.resultFromGM imageMagick("#{paths[0]}[-1]"), identityWorkFn, cb, "png"

# Make an explosion
splosion = (paths, cb) ->
  explode = path.join(__dirname, '..', 'data', 'img', 'explosion.gif')

  getImgInfo paths[0], (err, info) ->
    realInput = if info.isAnimated then [paths[0], "-coalesce"] else ["-delay", "100", paths[0]]

    workFn = (inputGm) ->
      # gm has functions for all of these, and it applies them in a different order
      # which is incorrect and honestly kind of infuriating.  so we manually work around.
      [
        ["-dispose", "Previous"],
        realInput,
        ["-resize", "128x128"],
        ["-background", "transparent"],
        ["-gravity", "center"],
        ["-extent", "128x128"],
        ["-set", "page", "+0+0"],
        ["-delay", "10"],
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
  getImgInfo paths[0], (err, info) ->
    # TODO: something with err
    size = info["size"]
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
          ["-alpha", "on"],
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

# shake an image
intensifies = (paths, cb) ->

  # start with the size -- used to calc speed and offset
  getImgInfo paths[0], (err, info) ->
    # TODO: something with err
    size = info["size"]
    maxDim = if size.width > size.height then size.width else size.height
    md = "#{maxDim}x#{maxDim}"
    w = size.width
    h = size.height
    ww = w * 2
    hh = h * 2

    workFn = (inputGm) ->
      # gm has functions for all of these, and it applies them in a different order
      # which is incorrect and honestly kind of infuriating.  so we manually work around.
      realInput = if info.isAnimated then ["#{paths[0]}[-1]", "-coalesce"] else [paths[0]]
      [
        ["-delay", "3"],
        realInput,
        ["-resize", "64x64+0+0"],
        ["\(", "+clone", "-repage", "+1+1", "\)"],
        ["\(", "+clone", "-repage", "+0+1", "\)"],
        # rather than dispose previous, we need to force it for all frames in memory.  affects animated gif inputs
        ["-set", "dispose", "Previous"],
        ["-loop", "0"],
      ].reduce ((acc, elem) -> acc.in.apply(acc, elem)), inputGm

    imageTransform.resultFromGM imageMagick(), workFn, cb, "gif"

# alter image color
alterColor = (paths, color, cb) ->
  workFn = (inputGm) ->
    # gm has functions for all of these, and it applies them in a different order
    # which is incorrect and honestly kind of infuriating.  so we manually work around.
    [
      ["-colorspace", "gray"],
      ["-sigmoidal-contrast", "10,60%"],
      ["-fill", color],
      ["-colorize", "65%"],
    ].reduce ((acc, elem) -> acc.in.apply(acc, elem)), inputGm

  imageTransform.resultFromGM imageMagick(paths[0]), workFn, cb, "png"

module.exports =
  identity: identity
  identity_gm: identity_gm
  firstframe: firstframe
  lastframe: lastframe
  splosion: splosion
  dealwithit: dealwithit
  intensifies: intensifies
  skintone_1: (paths, cb) -> alterColor paths, "rgb(255,255,255)", cb
  skintone_2: (paths, cb) -> alterColor paths, "rgb(248,220,186)", cb
  skintone_3: (paths, cb) -> alterColor paths, "rgb(223,188,147)", cb
  skintone_4: (paths, cb) -> alterColor paths, "rgb(189,143,100)", cb
  skintone_5: (paths, cb) -> alterColor paths, "rgb(152,100,56)", cb
  skintone_6: (paths, cb) -> alterColor paths, "rgb(88,69,56)", cb
