fs  = require 'fs'
gm  = require 'gm'

ImageContainer = require './imageContainer'

# this is the container for a final emoji result
# it needs to keep track of any error messages and
# any intermediate images created along the way.
# @representing is the string representing this result
class ImageResult
  constructor: (intermediateImages, errorMessages, resultImage) ->
    @intermediateImages = []
    @errorMessages = []
    @resultImage = null
    if intermediateImages != undefined
      @intermediateImages = @intermediateImages.concat intermediateImages
    if errorMessages != undefined
      @errorMessages = @errorMessages.concat errorMessages
    if resultImage != undefined
      @resultImage = resultImage

  # call all cleanup functions for images
  cleanup: ->
    i.cleanupCallback() for i in @allTempImages()

  # direct line to the image path of a result
  imgPath: ->
    @resultImage && @resultImage.path

  # whether we have a result
  isValid: ->
    @resultImage?

  addResult: (newResult) ->
    # any existing result is now sidelined
    @intermediateImages.push @resultImage if @resultImage?
    @resultImage = newResult

  # means we are disposing of this container and making another one
  allTempImages: ->
    if @resultImage != null
      @intermediateImages.concat([@resultImage])
    else
      @intermediateImages

  # result image size in bytes
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

  addTempImages: (imageContainers) ->
    for v in imageContainers
      @intermediateImages.push(v)

module.exports = ImageResult
