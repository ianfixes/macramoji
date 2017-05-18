emojiParser = require './parser'

class Extensimoji
  constructor: (@slackClient, @onError) ->

  parser: ->
    emojiParser

  parse: (str) ->
    emojiParser.parse str

  parseable: (str) ->
    try
      @parse str
      true
    catch e
      @onError(e)
      false

module.exports = Extensimoji
