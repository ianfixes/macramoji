tmp = require 'tmp'
fs  = require 'fs'
gm  = require 'gm'
path = require 'path'
callerId = require 'caller-id'

containers = {}

class ImageContainer
  constructor: (@path, @cleanupCallback) ->
    @cleaned = false

  # callback takes (err, imgContainer)
  @fromNewTempFile: (callback, callerName) ->
    if !callerName
      c = callerId.getData()
      callerName = "#{c.functionName}() #{path.basename(c.filePath)}:#{c.lineNumber}"

    tmp.file { discardDescriptor: true }, (err, newPath, fd, cleanupCallback) ->
      if err
        callback(err)
      else
        containers[newPath] = callerName
        ret = new ImageContainer newPath, () ->
          cleanupCallback()
          delete containers[newPath]
        callback(null, ret)

  @clearContainerTracker: ->
    containers = {}

  @existingContainerCount: ->
    Object.keys(containers).length

  @activeContainers: ->
    ret = {}
    for k, v of containers
      ret[k] = v
    ret

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
