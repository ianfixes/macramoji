gm  = require 'gm'
imageMagick = gm.subClass { imageMagick: true }

ImageResult = require './imageResult'

# inputGm is an opened GM chain
# workFn takes inputGm and returns GM
# cb takes (ImageResult)
resultFromGM = (inputGm, workFn, cb, format) ->
  initFn = (rawPath, cb2) ->
    path = if format then "#{format}:#{rawPath}" else rawPath
    tempGm = workFn(inputGm)
    console.log("GM command: #{tempGm.args()}")
    tempGm.write path, (err, result) ->
      console.log "resultFromGM err: #{err}" if err
      cb2(err, result)
  ImageResult.initFromNewTempFile initFn, cb

# this one is special because other transforms may need it
# cb takes err, result
normalize = (inImageResult, boxSize, cb) ->
  # path, imageresult, callback, input-graphics-magick
  workFn = (inputGm) ->
    inputGm.in("-coalesce")
  resultFromGM imageMagick(inImageResult.imgPath()), workFn, (err, outResult) ->
    return cb(err) if err
    outResult.addTempImages(inImageResult.allTempImages()) if outResult
    work2 = (inputGm2) ->
      inputGm.in("-resize", "#{boxSize}x#{boxSize}")
    resultFromGM imageMagick(outResult.imgPath()), workFn, (err2, outResult2) ->
      return cb(err2) if err2
      outResult2.addTempImages(outResult.allTempImages()) if outResult2
      cb(null, outResult2)

module.exports =
  normalize: normalize
  resultFromGM: resultFromGM
