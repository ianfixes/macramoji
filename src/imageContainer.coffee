tmp = require 'tmp'

class ImageContainer
  constructor: (@path, @cleanupCallback) ->

  # callback takes (err, imgContainer)
  @fromNewTempFile: (callback) ->
    tmp.file { discardDescriptor: true }, (err, path, fd, cleanupCallback) ->
      if err
        callback(err)
      else
        ret = new ImageContainer(path, cleanupCallback)
        callback(null, ret)


module.exports = ImageContainer
