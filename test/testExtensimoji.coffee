fs          = require 'fs'
test        = require 'tape'
ctest       = require 'tape-catch'
sinon       = require 'sinon'
Extensimoji = require '../src/'

ImageContainer = require '../src/imageContainer'
ImageResult = require '../src/imageResult'
ImageWorker = require '../src/imageWorker'
EmojiStore  = require '../src/emojiStore'

input1 = ':(dealwithit(:poop:, :kamina-glasses:))splosion:'

fakeEmojiStore = new EmojiStore
fakeEmojiStore.store =
  favico: 'http://tinylittlelife.org/favicon.ico'

fakeMacros =
  identity: (args, onComplete) ->
    initFn = (path, cb) ->
      fs.writeFileSync(path, fs.readFileSync(args[0]))
      cb()
    ImageResult.initFromNewTempFile initFn, onComplete

test 'extensimoji', (troot) ->
  test 'parser exists', (t) ->
    ee = new Extensimoji({}, undefined)
    t.ok(ee.parser(), 'parser exists')
    t.end()

  test 'parser parses positive input', (t) ->
    ee = new Extensimoji({}, undefined)
    t.equal(ee.parseable(input1), true)
    t.end()

  test 'does not parse negative input', (t) ->
    onErr = sinon.spy()
    ee = new Extensimoji({}, undefined)
    t.equal(ee.parseable(input1 + "crap"), false)
    t.end()

  test 'can reduce (tree into array)', (t) ->
    ee = new Extensimoji({}, undefined)
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
    ee = new Extensimoji('foo', 'bar')
    t.equal(ee.slackClient, 'foo')
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

    ee = new Extensimoji('foo', funks, 'baz')
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

    ee = new Extensimoji('foo', funks, 'baz')
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

    ee = new Extensimoji('foo', 'bar', 'baz')
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

    ee = new Extensimoji('foo', 'bar', 'baz')
    invalidNames = ee.invalidEmojiNames(entities, emoji)
    t.equal(invalidNames.length, 1)
    t.equal(invalidNames[0], 'bad')
    t.end()

  test 'can add good macros', (t) ->
    entities = [{ entity: 'funk', name: 'splosion' }]

    ee = new Extensimoji('foo', {}, 'baz')
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

    ee = new Extensimoji('foo', {}, 'baz')
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
    ee = new Extensimoji({}, undefined, undefined)
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
      ee = new Extensimoji null, fakeMacros, t.fail
      ee.emoji = fakeEmojiStore

      ee.process input, (slackResp) ->
        checkResult(t, slackResp, ee)
        #verifyDeletion(t, slackResp.imgResult)
        t.end()

  doe2e "Can do an end-to-end test with unparseable str", "zzzzz", (t, slackResp, ee) ->
    t.equal([
      "I couldn't parse `zzzzz` as macromoji:",
      "```Error: Parse error on line 1:",
      "zzzzz",
      "^",
      "Expecting ':', got 'LABEL'```"
    ].join("\n"), slackResp.message)

  doe2e "Can do an end-to-end test with bad funk", ":nope(:favico:):", (t, slackResp, ee) ->
    t.equal("I didn't understand some of `:nope(:favico:):`:\n • Unknown function names: nope",slackResp.message)

  doe2e "Can do an end-to-end test with bad emoji", ":identity(:poop:):", (t, slackResp, ee) ->
    t.equal("I didn't understand some of `:identity(:poop:):`:\n • Unknown emoji names: poop",slackResp.message)

  doe2e "Can do an end-to-end test with bad funk/emoji", ":nope(x(:poop:, :y:)):", (t, slackResp) ->
    t.equal([
      "I didn't understand some of `:nope(x(:poop:, :y:)):`:",
      " • Unknown function names: nope, x",
      " • Unknown emoji names: poop, y"].join("\n"), slackResp.message)

  doe2e "Can do an end-to-end test with good entities", ":identity(:favico:):", (t, slackResp, ee) ->
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
