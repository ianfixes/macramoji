ImageContainer = require './imageContainer'

# all exports in this file must act on an array of imageResults
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
# inputResult is an ImageResult
# workFn takes inputGm and returns GM
# cb takes (err, ImageResult)
doIO = (inputGm, inputResult, cb, workFn) ->
  ret = inputResult.supercede()
  # ret.addResult
  ImageContainer.fromNewTempFile (err, imgContainer) ->
    workFn(inputGm)
    .write resultPath, (err2) ->
      if err2
        ret.addTempImages [imgContainer]
        return cb(err2, ret)
      ret.addResult imgContainer
      cb(null, ret)

# cb takes err, result
normalize = (ir, boxSize, cb) ->
  doIO gm(ir.imgPath()), ir, cb, (inputGm) ->
    inputGm.resize(boxSize, boxSize)


module.exports =
  normalize: normalize
