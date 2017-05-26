emojiParser = require './parser'
unparser    = require './unparser'
EmojiStore  = require './emojiStore'

class Extensimoji
  constructor: (@slackClient, @macros, @onError) ->
    @emoji = EmojiStore(@slackClient)

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

  # we convert the parse tree to an imageWorker tree
  # don't forget to add the unparsed string as the first arg of imageworker
  # this callback does NOT take an imageworker... TODO what then
  prepare: (parseTree, callback) ->
    # if any names are invalid
    #     private reply:
    #

  # prepare the imageWorker tree
  # then process it
  processTree: (parseTree, callback) ->
    {}

  # get a message
  # see if its parseable
  # prepare it for processing
  # process it
  # upload it if things worked
  # else DM the user to say what went wrong
  # delete the temp files (cleanup)
  respondToChatMessage: (slackMessageObject) ->
    {}

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
