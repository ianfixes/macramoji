fs    = require 'fs'
test  = require 'tape'
ctest = require 'tape-catch'
sinon = require 'sinon'

EmojiProcessor = require '../src/emojiProcessor'
ImageContainer = require '../src/imageContainer'
ImageResult    = require '../src/imageResult'
ImageWorker    = require '../src/imageWorker'
EmojiStore     = require '../src/emojiStore'

input1 = '(dealwithit(:poop:, :kamina-glasses:))splosion'

emojiFetchFn = (cb) ->
  cb null,
    favico: 'http://tinylittlelife.org/favicon.ico'
fakeEmojiStore = new EmojiStore(emojiFetchFn, 0)

allMacros = require '../src/defaultMacros'

test 'EmojiProcessor', (troot) ->
  test 'parser exists', (t) ->
    ep = new EmojiProcessor({}, undefined)
    t.ok(ep.parser(), 'parser exists')
    t.end()

  test 'parser parses positive input', (t) ->
    ep = new EmojiProcessor({}, undefined)
    t.equal(ep.parseable(input1), true)
    t.end()

  test 'does not parse negative input', (t) ->
    onErr = sinon.spy()
    ep = new EmojiProcessor({}, undefined)
    t.equal(ep.parseable(input1 + " crap"), false)
    t.end()

  test 'can reduce (tree into array)', (t) ->
    ep = new EmojiProcessor({}, undefined)
    parseTree = ep.parse(input1)
    entities = ep.reduce parseTree, [], (acc, tree) ->
      acc.concat([
        entity: tree.entity
        name: tree.name
      ])

    expected = [
      { entity: 'funk', name: 'splosion' },
      { entity: 'funk', name: 'dealwithit' },
      { entity: 'emoji', name: 'poop' },
      { entity: 'emoji', name: 'kamina-glasses' }
    ]
    t.deepEqual(entities, expected)
    t.end()


  test 'understands positional arguments and initializes proper vars', (t) ->
    ep = new EmojiProcessor('foo', 'bar')
    t.equal(ep.emojiStore, 'foo')
    t.equal(ep.macros, 'bar')
    t.end()

  test 'can validate good function entities', (t) ->
    funks =
      dealwithit: "nevermind"
      splosion: "nevermind"

    entities = [
      { entity: 'funk', name: 'splosion' },
      { entity: 'funk', name: 'dealwithit' },
    ]

    ep = new EmojiProcessor('foo', funks, 'baz')
    t.equal(ep.invalidFunkNames(entities).length, 0)
    t.end()

  test 'can validate bad function entities', (t) ->
    funks =
      dealwithit: "nevermind"
      splosion: "nevermind"

    entities = [
      { entity: 'funk', name: 'splosion' },
      { entity: 'funk', name: 'bad' },
      { entity: 'funk', name: 'dealwithit' },
    ]

    ep = new EmojiProcessor('foo', funks, 'baz')
    invalidNames = ep.invalidFunkNames(entities)
    t.equal(invalidNames.length, 1)
    t.equal(invalidNames[0], 'bad')
    t.end()

  test 'can validate good emoji names', (t) ->
    emoji =
      poop: "nevermind"
      glasses: "nevermind"

    entities = [
      { entity: 'emoji', name: 'poop' },
      { entity: 'emoji', name: 'glasses' },
    ]

    ep = new EmojiProcessor('foo', 'bar', 'baz')
    t.equal(ep.invalidEmojiNames(entities, emoji).length, 0)
    t.end()


  test 'can validate bad emoji names', (t) ->
    emoji =
      poop: "nevermind"
      glasses: "nevermind"

    entities = [
      { entity: 'emoji', name: 'poop' },
      { entity: 'emoji', name: 'glasses' },
      { entity: 'emoji', name: 'bad' },
    ]

    ep = new EmojiProcessor('foo', 'bar', 'baz')
    invalidNames = ep.invalidEmojiNames(entities, emoji)
    t.equal(invalidNames.length, 1)
    t.equal(invalidNames[0], 'bad')
    t.end()

  test 'can add good macros', (t) ->
    entities = [{ entity: 'funk', name: 'splosion' }]

    ep = new EmojiProcessor('foo', {}, 'baz')
    # isn't there before
    invalidNames = ep.invalidFunkNames(entities)
    t.equal(invalidNames.length, 1)
    t.equal(invalidNames[0], 'splosion')
    # add it
    t.ok(ep.addMacro('splosion', (_) -> ))
    # is there now
    t.equal(ep.invalidFunkNames(entities).length, 0)
    t.end()

  test "can't add bad macros -- macros lacking a function", (t) ->
    entities = [{ entity: 'funk', name: 'splosion' }]

    ep = new EmojiProcessor('foo', {}, 'baz')
    # isn't there before
    invalidNames = ep.invalidFunkNames(entities)
    t.equal(invalidNames.length, 1)
    t.equal(invalidNames[0], 'splosion')
    # add it - fails
    t.notOk(ep.addMacro('splosion', 0))
    # isn't there now
    t.equal(ep.invalidFunkNames(entities).length, 1)
    t.end()

  test 'can reduce (tree into array)', (t) ->
    ep = new EmojiProcessor({}, undefined, undefined)
    parseTree = ep.parse(input1)
    entities = ep.reduce(parseTree, [], (acc, tree) ->
      acc.concat([
        entity: tree.entity
        name: tree.name
      ])
    )
    expected = [
      { entity: 'funk', name: 'splosion' },
      { entity: 'funk', name: 'dealwithit' },
      { entity: 'emoji', name: 'poop' },
      { entity: 'emoji', name: 'kamina-glasses' }
    ]
    t.deepEqual(entities, expected)
    t.end()

  verifySize = (t, container) ->
    t.equal(container.constructor.name, "ImageContainer", "Verify size of ImageContainers only")
    t.true(fs.existsSync(container.path), "the temp image #{container.path} should exist")
    t.equal(container.size(), 43, 'we downloaded what we expected')

  verifyFavico = (t, result, onComplete) ->
    t.deepEqual(result.errorMessages, [])
    t.equal(result.constructor.name, "ImageResult", "Verify favicos of ImageResults only")
    verifySize(t, result.resultImage)
    result.dimensions (err, dims) ->
      t.fail(err, 'getting dimensions succeeds') if err
      t.deepEqual(dims, {height: 1, width: 1})
      result.normalDimension (err, dim) ->
        t.fail(err, 'getting normal dimension succeeds') if err
        t.equal(dim, 1, 'dimension is 1')
        onComplete() if onComplete

  # do end-to-end test
  doe2e = (title, input, checkResult) ->
    ctest title, (t) ->
      ep = new EmojiProcessor fakeEmojiStore, fakeMacros

      ep.process input, (slackResp) ->
        checkResult t, slackResp, ep, () ->
          t.end()

  doe2e "Can do an end-to-end test with unparseable str", "zzzzz", (t, slackResp, ep, onComplete) ->
    t.equal([
      "I couldn't parse `zzzzz` as macromoji:",
      "```Error: Parse error on line 1:",
      "zzzzz",
      "-----^",
      "Expecting '(', got 'EOF'```"
    ].join("\n"), slackResp.message)
    onComplete()

  doe2e "Can do an end-to-end test with bad funk", "nope(:favico:)", (t, slackResp, ep, onComplete) ->
    t.equal("I didn't understand some of `nope(:favico:)`:\n • Unknown function names: nope",slackResp.message)
    onComplete()

  doe2e "Can do an end-to-end test with bad emoji", "identity(:pooop:)", (t, slackResp, ep, onComplete) ->
    t.equal("I didn't understand some of `identity(:pooop:)`:\n • Unknown emoji names: pooop",slackResp.message)
    onComplete()

  doe2e "Can do an end-to-end test with bad funk/emoji", "nope(x(:pooop:, :y:))", (t, slackResp, ep, onComplete) ->
    t.equal([
      "I didn't understand some of `nope(x(:pooop:, :y:))`:",
      " • Unknown function names: nope, x",
      " • Unknown emoji names: pooop, y"].join("\n"), slackResp.message)
    onComplete()

  doe2e "Can do an end-to-end test with builtin emoji", "identity(:copyright:)", (t, slackResp, ep, onComplete) ->
    t.equal(slackResp.message, null)
    t.true(slackResp.imgResult)
    t.equal(slackResp.imgResult.constructor.name, "ImageResult")
    t.equal("identity-copyright", slackResp.fileDesc)
  doe2e "Can do an end-to-end test with good entities", "identity(:favico:)", (t, slackResp, ep, onComplete) ->
    t.equal(slackResp.message, null)
    t.true(slackResp.imgResult)
    t.equal(slackResp.imgResult.constructor.name, "ImageResult")
    t.equal("identity-favico", slackResp.fileDesc)
    emojiResult = ee.workTree.resolvedArgs[0]
    verifyFavico(t, emojiResult)
    verifyFavico(t, ee.workTree.result)
    verifyFavico(t, slackResp.imgResult)  # same as prev line
    t.equal(slackResp.imgResult.allTempImages().length, 2)

  troot.end()
