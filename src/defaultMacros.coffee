fs = require 'fs'
path = require 'path'

imageTransform = require './imageTransform'
ImageResult    = require './imageResult'

# TODO: all exports in this file must act on an array of paths
# and a callback that takes (err, ImageResult)

identity = (paths, onComplete) ->
  initFn = (path, cb) ->
    fs.writeFileSync(path, fs.readFileSync(paths[0]))
    cb()
  ImageResult.initFromNewTempFile initFn, onComplete


splosion = (paths, cb) ->
  # path.join(__dirname, '..', 'data', sourceFile)

  # convert -dispose Previous "${input_file_name_raw}" -resize 128x128 -background transparent -gravity center -extent 128x128 -set page +0+0 -set delay 100 explosion.gif -loop 0 "${file_name_to_output}";


module.exports =
  identity: identity
  splosion: splosion
