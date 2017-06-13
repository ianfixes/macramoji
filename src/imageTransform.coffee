gm  = require 'gm'

ImageResult = require './imageResult'

# inputGm is an opened GM chain
# workFn takes inputGm and returns GM
# cb takes (ImageResult)
resultFromGM = (inputGm, workFn, cb, format) ->
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
  resultFromGM gm(inImageResult.imgPath()), workFn, (err, outResult) ->
    if outResult
      outResult.addTempImages(inImageResult.allTempImages())
    cb(err, outResult)

module.exports =
  normalize: normalize
  resultFromGM: resultFromGM
