tmp = require 'tmp'
fs  = require 'fs'
gm  = require 'gm'

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

  # callback takes (err, imgContainer)
  createTempImage: (callback) ->
    tmp.file { discardDescriptor: true }, (err, path, fd, cleanupCallback) ->
      if err
        callback(err)
      else
        ret = new ImageContainer(path, cleanupCallback)
        callback(null, ret)

  # callback takes (err, tmpImagePath)
  # TODO: it's late and i feel like this is a dumb way to structure
  #   these callbacks
  addTempImage: (callback) ->
    @createTempImage (err, imgContainer) =>
      return callback(err) if err
      @tempImages.push imgContainer
      callback(null, imgContainer.path)

  # callback takes (err, tmpImagePath)
  addResultImage: (callback) ->
    @createTempImage (err, imgContainer) =>
      return callback(err) if err
      @resultImage = imgContainer
      callback(null, imgContainer.path)


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

  addTempImages: (imageContainers) ->
    imageContainers.forEach (v) => @tempImages.push(v)

  addErrors: (errorMessages) ->
    errorMessages.forEach (v) => @errorMessages.push(v)

  supercede: ->
    ret = new ImageResult()
    ret.addTempImages(@allTempImages)
    ret.addErrors(@errorMessages)
    ret

module.exports = ImageResult
