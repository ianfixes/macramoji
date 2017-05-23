# https://github.com/benbria/coffee-coverage/blob/master/docs/HOWTO-tape-not-mocha.md

test        = require 'tape'
sinon       = require 'sinon'
Extensimoji = require '../src/'

input1 = ':(dealwithit(:poop:, :kamina-glasses:))splosion:'

test 'parser', (troot) ->
  test 'exists', (t) ->
    ee = new Extensimoji({}, undefined, undefined)
    t.ok(ee.parser(), 'parser exists')
    t.end()

  test 'parses positive input', (t) ->
    ee = new Extensimoji({}, undefined, undefined)
    t.equal(ee.parseable(input1), true)
    t.end()

  test 'does not parse negative input', (t) ->
    onErr = sinon.spy()
    ee = new Extensimoji({}, undefined, onErr)
    t.equal(ee.parseable(input1 + "crap"), false)
    t.assert(onErr.firstCall.args[0].message.includes("Expecting 'EOF'"),
      "Error message includes parse info")
    t.end()

  test 'produces proper tree', (t) ->
    ee = new Extensimoji({}, undefined, undefined)
    expected =
      entity: 'funk'
      name: 'splosion'
      is: 'suffix'
      args: [
        entity: 'funk'
        name: 'dealwithit'
        is: 'prefix'
        args: [
          {
            entity: 'emoji'
            name: 'poop'
          },
          {
            entity: 'emoji'
            name: 'kamina-glasses'
          }
        ]
      ]
    t.deepEqual(ee.parse(input1), expected)
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
