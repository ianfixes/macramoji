fs = require 'fs'
path = require 'path'
gm = require 'gm'
imageMagick = gm.subClass { imageMagick: true }


imageTransform = require './imageTransform'
ImageResult    = require './imageResult'

# TODO: all exports in this file must act on an array of paths
# and a callback that takes (err, ImageResult)

# Output what we input
identity = (paths, onComplete) ->
  initFn = (path, cb) ->
    fs.writeFileSync(path, fs.readFileSync(paths[0]))
    cb()
  ImageResult.initFromNewTempFile initFn, onComplete

# output what we input, but use GM
identity_gm = (paths, cb) ->
  explode = path.join(__dirname, '..', 'data', 'img', 'explosion.gif')
  workFn = (inputGm) ->
    inputGm

  imageTransform.resultFromGM gm(paths[0]), workFn, cb, "gif"

# Make an explosion
splosion = (paths, cb) ->
  explode = path.join(__dirname, '..', 'data', 'img', 'explosion.gif')
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
      ["-set", "delay", "100"],
      [explode],
      ["-loop", "0"],
    ].reduce ((acc, elem) -> acc.in.apply(acc, elem)), inputGm



  imageTransform.resultFromGM imageMagick(), workFn, cb, "gif"



module.exports =
  identity: identity
  identity_gm: identity_gm
  splosion: splosion
