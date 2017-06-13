emojiParser   = require './parser'
unparser      = require './unparser'
EmojiStore    = require './emojiStore'
ImageWorker   = require './imageWorker'
SlackResponse = require './slackResponse'

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

  # get a summary of all name-related problems that might exist
  entityProblems: (parseTree) ->
    entities = @reduce parseTree, [], (acc, tree) ->
      acc.concat([
        entity: tree.entity
        name: tree.name
      ])

    badFunks = @invalidFunkNames(entities)
    badEmoji = @invalidEmojiNames(entities, @emoji.store)

    msgs = []
    if badFunks.length > 0
      msgs.push "Unknown function names: #{badFunks.join(', ')}"
    if badEmoji.length > 0
      msgs.push "Unknown emoji names: #{badEmoji.join(', ')}"
      # TODO: refresh and retry somehow?
    msgs

  # we convert the parse tree to an imageWorker tree
  # don't forget to add the unparsed string as the first arg of imageworker
  # this callback does NOT take an imageworker... TODO what then
  prepare: (parseTree) ->
    # turn a parsed tree back into a string, for better error messages
    prep_helper = (tree) =>
      unparsed = unparser.unparse(tree)
      if tree.entity == 'emoji'
        return new ImageWorker unparsed, [], @emoji.workFn(tree.name)

      args = tree.args.map (x) -> prep_helper(x)
      return new ImageWorker unparsed, args, @macros[tree.name]
    prep_helper(parseTree)

  # get a message
  # see if its parseable
  # prepare it for processing
  # process it
  # callback with a slackResponse object
  process: (emojiStr, onComplete) =>
    ret = new SlackResponse
    parseTree = null
    try
      parseTree = @parse emojiStr
    catch err
      ret.setMessage "I couldn't parse `#{emojiStr}` as macromoji:\n```#{err}```"
      return onComplete(ret)

    probs = @entityProblems(parseTree)
    if probs.length > 0
      probList = (probs.map (x) -> "\n • #{x}").join("")
      ret.setMessage "I didn't understand some of `#{emojiStr}`:#{probList}"
      return onComplete(ret)

    @workTree = @prepare(parseTree)
    @workTree.resolve (imgResult) ->
      if imgResult.isValid()
        ret.setUpload(imgResult, unparser.unparseEnglish(parseTree))
      else
        probList = (imgResult.errorMessages.map (x) -> "\n • #{x}").join("")
        ret.setMessage("Processing `#{emojiStr}` produced the following errors: #{probList}")
      return onComplete(ret)

  # process a message
  # respond to user
  # delete the temp files (cleanup)
  respondToChatMessage: (emojiStr, slackMessageObject) ->
    @process emojiStr, (slackResp) ->
      slackResp.respond(slackMessageObject)

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
