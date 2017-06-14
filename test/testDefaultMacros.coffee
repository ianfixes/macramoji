test  = require 'tape'
sinon = require 'sinon'
gm    = require 'gm'
fs    = require 'fs'
path  = require 'path'

defaultMacros = require '../src/defaultMacros'

rage1 = path.join(__dirname, 'img', 'rage1.gif')
rage1_id = path.join(__dirname, 'img', 'identity-rage1.gif')

outPath = (name) ->  path.join(__dirname, 'artifacts', name)
createArtifact = (inPath, name) ->
  fs.createReadStream(inPath).pipe(fs.createWriteStream(outPath(name)))

test "defaultMacros", (troot) ->
  test "dealwithit single arg", (t) ->
    defaultMacros.dealwithit [rage1], (result) ->
      createArtifact(result.imgPath(), 'dealtwithit.gif')
      t.end()

  test "dealwithit single arg glasses too big", (t) ->
    defaultMacros.dealwithit [rage1_id], (result) ->
      createArtifact(result.imgPath(), 'dealtwithit_bigglasses.gif')
      t.end()

  troot.end()
