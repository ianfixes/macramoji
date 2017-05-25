fs = require 'fs'
gm = require 'gm'

class ImageContainer
  constructor: (@path, @cleanupCallback) ->

class ImageResult
  constructor: ->
    @tempImages    = []
    @errorMessages = []
    @resultImage   = null

  cleanup: ->
    i.cleanupCallback() for i in @allTempImages()

  imgPath: ->
    @resultImage && @resultImage.path

  isValid: ->
    @resultImage?

  addResult: (path, cleanupFn) ->
    @resultImage = new ImageContainer(path, cleanupFn)

  # means we are disposing of this container and making another one
  allTempImages: ->
    if @resultImage != null
      @tempImages.concat([@resultImage])
    else
      @tempImages

  size: ->
    p = @imgPath()
    p && fs.statSync(p).size

  # raw dimensions
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
