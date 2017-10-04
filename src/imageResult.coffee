fs  = require 'fs'
gm  = require 'gm'
path = require 'path'
callerId = require 'caller-id'

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

  # initFn takes (path, cb) where cb is (err)
  # onComplete takes (imgResult)
  @initFromNewTempFile: (initFn, onComplete) ->
    c = callerId.getData()
    callerName = "#{c.functionName}() #{path.basename(c.filePath)}:#{c.lineNumber} via ImageResult.initFromNewTempFile"

    ret = new ImageResult
    ImageContainer.fromNewTempFile (err, imgContainer) ->
      if err
        ret.addErrors [err]
        return onComplete(ret)

      initFn imgContainer.path, (err2) ->
        if err2
          ret.addErrors([err2])
          ret.addTempImages [imgContainer]
          return onComplete(ret)

        ret.addResult imgContainer
        onComplete(ret)
    , callerName

  provenance: ->
    sources = ImageContainer.activeContainers()
    i.source() for i in @allTempImages()


  # call all cleanup functions for images
  cleanup: ->
    before = ImageContainer.existingContainerCount()
    i.cleanup() for i in @allTempImages()
    numDeleted = before - ImageContainer.existingContainerCount()
    console.log("Cleanup appears to have deleted #{numDeleted} temp images")

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
    @resultImage && @resultImage.size()

  # raw dimensions
  # callback gives (err, {width: x, height: y})
  dimensions: (cb) =>
    return cb("Can't get dimensions of null resultImage") unless @isValid()
    @resultImage.dimensions cb

  # whichever dimension is bigger
  # callback gives (err, dimensionInteger)
  normalDimension: (cb) =>
    return cb("Can't get normalDimension of null resultImage") unless @isValid()
    @resultImage.normalDimension cb

  addTempImage: (imageContainer) ->
    @intermediateImages.push(imageContainer)

  addTempImages: (imageContainers) ->
    imageContainers.forEach (v) => @addTempImage(v)

  mergeTempImages: (imageResult) =>
    @addTempImages(imageResult.allTempImages())

  addErrors: (errorMessages) ->
    errorMessages.forEach (v) => @errorMessages.push(v)

module.exports = ImageResult
