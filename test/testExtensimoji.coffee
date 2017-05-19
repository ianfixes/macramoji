test        = require 'tape'
sinon       = require 'sinon'
Extensimoji = require '../src/'

input1 = ':(dealwithit(:poop:, :kamina-glasses:))splosion:'

test 'extensimoji', (troot) ->
  test 'understands positional arguments and initializes proper vars', (t) ->
    ee = new Extensimoji('foo', 'bar', 'baz')
    t.equal(ee.slackClient, 'foo')
    t.equal(ee.macros, 'bar')
    t.equal(ee.onError, 'baz')
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
  troot.end()
