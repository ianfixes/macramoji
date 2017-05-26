# all exports in this file must act on imageResults

# https://coffeescript-cookbook.github.io/chapters/arrays/check-type-is-array
isArray = (value) ->
  value and
    typeof value is 'object' and
    value instanceof Array and
    typeof value.length is 'number' and
    typeof value.splice is 'function' and
    not ( value.propertyIsEnumerable 'length' )

# inputGm is an opened GM chain
# inputResults is an ImageResult
# workFn takes inputGm and returns GM
# cb takes (err, ImageResult)
doIO = (inputGm, inputResult, cb, workFn) ->
  ret = inputResult.supercede()
  ret.addResultImage (err, resultPath) ->
    workFn(inputGm)
    .write resultPath, (err2) ->
      return cb(err) if err2
      cb(null, ret)

# cb takes err, result
normalize = (ir, boxSize, cb) ->
  doIO gm(ir.imgPath), ir, cb, (inputGm) ->
    inputGm.resize(boxSize, boxSize)


module.exports =
  normalize: normalize
