fs = require 'fs'

class ImageContainer
  constructor: (@path, @cleanupCallback) ->

  cleanup: ->
    @cleanupCallback()

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
    i.cleanup() for i in @allTempImages()

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
    fs.statSync(@imgPath()).size

module.exports = ImageResult
