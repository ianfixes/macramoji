gm  = require 'gm'

ImageContainer = require './imageContainer'
ImageResult = require './imageResult'

# TODO: all exports in this file must act on an array of paths
# and a callback that takes (err, ImageResult)

# https://coffeescript-cookbook.github.io/chapters/arrays/check-type-is-array
isArray = (value) ->
  value and
    typeof value is 'object' and
    value instanceof Array and
    typeof value.length is 'number' and
    typeof value.splice is 'function' and
    not ( value.propertyIsEnumerable 'length' )

# inputGm is an opened GM chain
# workFn takes inputGm and returns GM
# cb takes (ImageResult)
doIO = (inputGm, workFn, cb, format) ->
  initFn = (rawPath, cb2) ->
    path = if format then "#{format}:#{rawPath}" else rawPath
    workFn(inputGm)
    .write path, cb2

  ImageResult.initFromNewTempFile initFn, cb

# this one is special because other transforms may need it
# cb takes err, result
normalize = (inImageResult, boxSize, cb) ->
  # path, imageresult, callback, input-graphics-magick
  workFn = (inputGm) ->
    inputGm.resize(boxSize, boxSize)
  doIO gm(inImageResult.imgPath()), workFn, (err, outResult) ->
    if outResult
      outResult.addTempImages(inImageResult.allTempImages())
    cb(err, outResult)


module.exports =
  normalize: normalize
