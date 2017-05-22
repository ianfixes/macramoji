fs = require 'fs'
gm = require 'gm'

class ImageContainer
  constructor: (@path, @cleanupCallback) ->

class ImageResult
  constructor: ->
    @tempImages    = []
    @errorMessages = []
    @resultImage   = null

  addTempImages: (imageContainers) ->
    imageContainers.forEach (v) => @tempImages.push(v)

  addErrors: (errorMessages) ->
    errorMessages.forEach (v) => @errorMessages.push(v)

  cleanup: ->
    i.cleanupCallback() for i in @allTempImages()

  imgPath: ->
    @resultImage && @resultImage.path

  addResult: (path, cleanupFn) ->
    @resultImage = new ImageContainer(path, cleanupFn)

  # means we are disposing of this container and making another one
  allTempImages: ->
    if @resultImage != null
      @tempImages.concat([@resultImage])
    else
      @tempImages

  supercede: ->
    ret = new ImageResult()
    ret.addTempImages(@allTempImages)
    ret.addErrors(@errorMessages)
    ret

  size: ->
    p = @imgPath()
    p && fs.statSync(p).size

  # raw dimension
  # callback gives (err, {width: x, height: y})
  dimensions: (cb) ->
    gm(@imgPath()).size cb

  # whichever dimension is bigger
  # callback gives (err, dimensionInteger)
  normalDimension: (cb) ->
    @dimensions (err, dims) ->
      return cb(err) if err
      cb(null, if dims.width > dims.height then dims.width else dims.height)

module.exports = ImageResult
