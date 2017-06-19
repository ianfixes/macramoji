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

fakeClient =
  emoji:
    list: (cb) ->
      cb null,
        emoji:
          favico: 'http://tinylittlelife.org/favicon.ico'
fakeEmojiStore = new EmojiStore(fakeClient, 0)

fakeMacros =
  identity: (args, onComplete) ->
    initFn = (path, cb) ->
      fs.writeFileSync(path, fs.readFileSync(args[0]))
      cb()
    ImageResult.initFromNewTempFile initFn, onComplete

test 'EmojiProcessor', (troot) ->
  test 'parser exists', (t) ->
    ee = new EmojiProcessor({}, undefined)
    t.ok(ee.parser(), 'parser exists')
    t.end()

  test 'parser parses positive input', (t) ->
    ee = new EmojiProcessor({}, undefined)
    t.equal(ee.parseable(input1), true)
    t.end()

  test 'does not parse negative input', (t) ->
    onErr = sinon.spy()
    ee = new EmojiProcessor({}, undefined)
    t.equal(ee.parseable(input1 + " crap"), false)
    t.end()

  test 'can reduce (tree into array)', (t) ->
    ee = new EmojiProcessor({}, undefined)
    parseTree = ee.parse(input1)
    entities = ee.reduce parseTree, [], (acc, tree) ->
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
    ee = new EmojiProcessor('foo', 'bar')
    t.equal(ee.emojiStore, 'foo')
    t.equal(ee.macros, 'bar')
    t.end()

  test 'can validate good function entities', (t) ->
    funks =
      dealwithit: "nevermind"
      splosion: "nevermind"

    entities = [
      { entity: 'funk', name: 'splosion' },
      { entity: 'funk', name: 'dealwithit' },
    ]

    ee = new EmojiProcessor('foo', funks, 'baz')
    t.equal(ee.invalidFunkNames(entities).length, 0)
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

    ee = new EmojiProcessor('foo', funks, 'baz')
    invalidNames = ee.invalidFunkNames(entities)
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

    ee = new EmojiProcessor('foo', 'bar', 'baz')
    t.equal(ee.invalidEmojiNames(entities, emoji).length, 0)
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

    ee = new EmojiProcessor('foo', 'bar', 'baz')
    invalidNames = ee.invalidEmojiNames(entities, emoji)
    t.equal(invalidNames.length, 1)
    t.equal(invalidNames[0], 'bad')
    t.end()

  test 'can add good macros', (t) ->
    entities = [{ entity: 'funk', name: 'splosion' }]

    ee = new EmojiProcessor('foo', {}, 'baz')
    # isn't there before
    invalidNames = ee.invalidFunkNames(entities)
    t.equal(invalidNames.length, 1)
    t.equal(invalidNames[0], 'splosion')
    # add it
    t.ok(ee.addMacro('splosion', (_) -> ))
    # is there now
    t.equal(ee.invalidFunkNames(entities).length, 0)
    t.end()

  test "can't add bad macros -- macros lacking a function", (t) ->
    entities = [{ entity: 'funk', name: 'splosion' }]

    ee = new EmojiProcessor('foo', {}, 'baz')
    # isn't there before
    invalidNames = ee.invalidFunkNames(entities)
    t.equal(invalidNames.length, 1)
    t.equal(invalidNames[0], 'splosion')
    # add it - fails
    t.notOk(ee.addMacro('splosion', 0))
    # isn't there now
    t.equal(ee.invalidFunkNames(entities).length, 1)
    t.end()

  test 'can reduce (tree into array)', (t) ->
    ee = new EmojiProcessor({}, undefined, undefined)
    parseTree = ee.parse(input1)
    entities = ee.reduce(parseTree, [], (acc, tree) ->
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

  verifyFavico = (t, result) ->
    t.deepEqual(result.errorMessages, [])
    t.equal(result.constructor.name, "ImageResult", "Verify favicos of ImageResults only")
    verifySize(t, result.resultImage)
    result.dimensions (err, dims) ->
      t.fail(err, 'getting dimensions succeeds') if err
      t.deepEqual(dims, {height: 1, width: 1})
      result.normalDimension (err, dim) ->
        t.fail(err, 'getting normal dimension succeeds') if err
        t.equal(dim, 1, 'dimension is 1')

  verifyDeletion = (t, result) ->
    result.cleanup()
    t.false(fs.existsSync(result.imgPath()), 'image should be deleted')


  # do end-to-end test
  doe2e = (title, input, checkResult) ->
    ctest title, (t) ->
      ee = new EmojiProcessor fakeEmojiStore, fakeMacros

      ee.process input, (slackResp) ->
        checkResult(t, slackResp, ee)
        #verifyDeletion(t, slackResp.imgResult)
        t.end()

  doe2e "Can do an end-to-end test with unparseable str", "zzzzz", (t, slackResp, ee) ->
    t.equal([
      "I couldn't parse `zzzzz` as macromoji:",
      "```Error: Parse error on line 1:",
      "zzzzz",
      "-----^",
      "Expecting '(', got 'EOF'```"
    ].join("\n"), slackResp.message)

  doe2e "Can do an end-to-end test with bad funk", "nope(:favico:)", (t, slackResp, ee) ->
    t.equal("I didn't understand some of `nope(:favico:)`:\n • Unknown function names: nope",slackResp.message)

  doe2e "Can do an end-to-end test with bad emoji", "identity(:pooop:)", (t, slackResp, ee) ->
    t.equal("I didn't understand some of `identity(:pooop:)`:\n • Unknown emoji names: pooop",slackResp.message)

  doe2e "Can do an end-to-end test with bad funk/emoji", "nope(x(:pooop:, :y:))", (t, slackResp) ->
    t.equal([
      "I didn't understand some of `nope(x(:pooop:, :y:))`:",
      " • Unknown function names: nope, x",
      " • Unknown emoji names: pooop, y"].join("\n"), slackResp.message)

  doe2e "Can do an end-to-end test with builtin emoji", "identity(:copyright:)", (t, slackResp, ee) ->
    t.equal(slackResp.message, null)
    t.true(slackResp.imgResult)
    t.equal(slackResp.imgResult.constructor.name, "ImageResult")
    t.equal("identity-copyright", slackResp.fileDesc)
    t.equal(slackResp.imgResult.allTempImages().length, 2)

  doe2e "Can do an end-to-end test with good entities", "identity(:favico:)", (t, slackResp, ee) ->
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
