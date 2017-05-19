emojiParser = require './parser'

class Extensimoji
  constructor: (@slackClient, @macros, @onError) ->

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

  addMacro: (name, fn) ->
    if typeof fn isnt 'function'
      false
    else
      @macros[name] = fn
      true

  # create a list of things that aren't allowed
  # entities is the input list of objects
  # targetType is the desired value of the 'entity' key (others ignored)
  # allowed is an object; the keys are what's allowed
  invalidAnything: (entities, targetType, allowed) ->
    onlyTargetType = entities.filter (e) -> e.entity == targetType
    names = onlyTargetType.map (e) -> e.name
    names.filter (n) -> !(n of allowed)

  invalidFunkNames: (entities) ->
    @invalidAnything entities, 'funk', @macros

  invalidEmojiNames: (entities, definedEmoji) ->
    @invalidAnything entities, 'emoji', definedEmoji

  reduce: (parseTree, acc, onEach) ->
    here = onEach(acc, parseTree)
    if 'args' of parseTree
      args = parseTree['args']
      tmp = (acc2, subTree) =>
        @reduce subTree, acc2, onEach
      args.reduce tmp, here
    else
      here

module.exports = Extensimoji
