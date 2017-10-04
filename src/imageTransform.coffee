gm  = require 'gm'
imageMagick = gm.subClass { imageMagick: true }

ImageResult = require './imageResult'

# inputGm is an opened GM chain
# workFn takes inputGm and returns GM
# cb takes (ImageResult)
resultFromGM = (inputGm, workFn, cb, format) ->
  initFn = (rawPath, cb2) ->
    newPath = if format then "#{format}:#{rawPath}" else rawPath
    tempGm = workFn(inputGm)  # assign to a temp variable so we can log args prior to writing
    console.log("GM command: #{tempGm.args()} >> #{newPath}")
    tempGm.write newPath, (err, result) ->
      console.log "resultFromGM err writing #{newPath}: #{err}" if err
      cb2(err, result)
  ImageResult.initFromNewTempFile initFn, cb

# this one is special because other transforms may need it
# cb takes ImageResult
normalizePath = (inPath, boxSize, cb) ->
  # path, imageresult, callback, input-graphics-magick
  workFn = (inputGm) ->
    inputGm.in("-background", "none").in("-alpha", "on").in("-coalesce")
  resultFromGM imageMagick(inPath), workFn, (outResult) ->
    return cb(outResult) unless outResult.isValid()
    work2 = (inputGm2) ->
      inputGm2.in("-resize", "#{boxSize}x#{boxSize}")
    cb2 = (outResult2) ->
      outResult2.addTempImages(outResult.allTempImages())
      cb(outResult2)
    resultFromGM imageMagick(outResult.imgPath()), work2, cb2

# normalize an ImageResult
# cb takes ImageResult
normalize = (inImageResult, boxSize, cb) ->
  normalizePath inImageResult.imgPath(), boxSize, (outResult) ->
    outResult.addTempImages(inImageResult.allTempImages())
    cb(outResult)

module.exports =
  normalizePath: normalizePath
  normalize: normalize
  resultFromGM: resultFromGM
