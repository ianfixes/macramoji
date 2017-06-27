tmp = require 'tmp'
fs  = require 'fs'
gm  = require 'gm'

containersExisting = 0

class ImageContainer
  constructor: (@path, @cleanupCallback) ->
    @cleaned = false

  # callback takes (err, imgContainer)
  @fromNewTempFile: (callback) ->
    tmp.file { discardDescriptor: true }, (err, path, fd, cleanupCallback) ->
      if err
        callback(err)
      else
        containersExisting = containersExisting + 1
        ret = new ImageContainer path, () ->
          containersExisting = containersExisting - 1
          cleanupCallback()
        callback(null, ret)

  @existingContainerCount: ->
    containersExisting

  cleanup: =>
    @cleanupCallback && !@cleaned && @cleanupCallback()
    @cleaned = true

  # result image size in bytes
  size: ->
    fs.statSync(@path).size

  # raw dimensions
  # callback gives (err, {width: x, height: y})
  dimensions: (cb) ->
    gm(@path).size cb

  # whichever dimension is bigger
  # callback gives (err, dimensionInteger)
  normalDimension: (cb) ->
    @dimensions (err, dims) ->
      return cb(err) if err
      cb(null, if dims.width > dims.height then dims.width else dims.height)


module.exports = ImageContainer
