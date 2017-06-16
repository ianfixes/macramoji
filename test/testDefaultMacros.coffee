test  = require 'tape'
sinon = require 'sinon'
gm    = require 'gm'
fs    = require 'fs'
path  = require 'path'

defaultMacros = require '../src/defaultMacros'

inPath  = (name) -> path.join(__dirname, 'img', name)
outPath = (name) -> path.join(__dirname, 'artifacts', name)
fileNoExt = (name) -> path.basename name, path.extname(name)
bob      = inPath 'bob.png'
rage1    = inPath 'rage1.gif'
rage1_id = inPath 'identity-rage1.gif'
kamina   = inPath 'kamina_glasses.png'


test "defaultMacros", (troot) ->

  artifacts = []

  createArtifact = (inputPath, filename) ->
    outputPath = outPath(filename)
    fs.createReadStream(inputPath).pipe(fs.createWriteStream(outputPath))
    artifacts.push
      name: fileNoExt(filename)
      path: filename

  test "dealwithit single arg", (t) ->
    defaultMacros.dealwithit [rage1], (result) ->
      createArtifact(result.imgPath(), 'dealwithit_default_glasses.gif')
      t.end()

  test "dealwithit single arg no alpha channel", (t) ->
    defaultMacros.dealwithit [bob], (result) ->
      createArtifact(result.imgPath(), 'dealwithit_noalpha_default_glasses.gif')
      t.end()

  test "dealwithit single arg glasses too big", (t) ->
    defaultMacros.dealwithit [rage1_id], (result) ->
      createArtifact(result.imgPath(), 'dealtwithit_default_glasses_resized.gif')
      t.end()

  test "dealwithit double arg", (t) ->
    defaultMacros.dealwithit [rage1, kamina], (result) ->
      createArtifact(result.imgPath(), 'dealwithit_kamina_glasses.gif')
      t.end()

  test "dealwithit double arg glasses too big", (t) ->
    defaultMacros.dealwithit [rage1_id, kamina], (result) ->
      createArtifact(result.imgPath(), 'dealtwithit_kamina_glasses_resized.gif')
      t.end()

  test "Explosion from static image", (t) ->
    defaultMacros.splosion [rage1], (result) ->
      createArtifact(result.imgPath(), 'static_splosion.gif')
      t.end()

  test "Explosion from static image no alpha", (t) ->
    defaultMacros.splosion [bob], (result) ->
      createArtifact(result.imgPath(), 'static_noalpha_splosion.gif')
      t.end()

  test "Explosion from static image", (t) ->
    defaultMacros.dealwithit [rage1, kamina], (result1) ->
      defaultMacros.splosion [result1.imgPath()], (result) ->
        createArtifact(result.imgPath(), 'animation_splosion.gif')
        t.end()

  test "intensifies from big image", (t) ->
    defaultMacros.intensifies [rage1], (result) ->
      createArtifact(result.imgPath(), 'intensifies_big.gif')
      t.end()

  test "intensifies from smaller image", (t) ->
    defaultMacros.intensifies [rage1_id], (result) ->
      createArtifact(result.imgPath(), 'intensifies_small.gif')
      t.end()

  test "creates report", (t) ->
    artifactRows = artifacts.map (a) -> "<tr><td><img src='#{a.path}'></td><td>#{a.name}</td></tr>"

    content = [
      "<html><head><title>Artifacts</title></head><body>",
      "<table border='1'>",
      artifactRows.join("\n"),
      "</table>",
      "</body></html>"].join("\n")
    fs.writeFileSync(outPath("index.html"), content)
    t.end()

  troot.end()
