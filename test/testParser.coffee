# https://github.com/benbria/coffee-coverage/blob/master/docs/HOWTO-tape-not-mocha.md

test     = require 'tape'
sinon    = require 'sinon'
parser   = require '../src/parser'
unparser = require '../src/unparser'

unparsed = ':(dealwithit(:poop:, :kamina-glasses:))splosion:'
parsed =
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

test 'parser', (troot) ->

  test 'produces proper tree', (t) ->
    t.deepEqual(parser.parse(unparsed), parsed)
    t.end()

  test 'produces proper string', (t) ->
    t.deepEqual(unparser.unparse(parsed), unparsed)
    t.end()

  troot.end()
