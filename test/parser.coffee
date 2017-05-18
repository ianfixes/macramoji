test        = require 'tape'
sinon       = require 'sinon'
Extensimoji = require '../src/'

input1 = ':(:dealwithit(:poop:, :kamina-glasses:):)splosion:'

test 'parser', (troot) ->
  test 'handles positive case', (t) ->
    ee = new Extensimoji({}, undefined)
    t.equal(ee.parseable(input1), true)
    t.end()

  test 'handles negative case', (t) ->
    onErr = sinon.spy()
    ee = new Extensimoji({}, onErr)
    t.equal(ee.parseable(input1 + "crap"), false)
    t.assert(onErr.firstCall.args[0].message.includes("Expecting 'EOF'"),
      "Error message includes parse info")
    t.end()

  test 'produces proper tree', (t) ->
    ee = new Extensimoji({}, undefined)
    expected =
      entity: 'funk'
      name: 'splosion'
      args: [
        entity: 'funk'
        name: 'dealwithit'
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


  troot.end()
