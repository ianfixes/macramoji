test  = require 'tape'
sinon = require 'sinon'
gm    = require 'gm'
fs    = require 'fs'
path  = require 'path'

defaultMacros = require '../src/defaultMacros'

inPath  = (name) -> path.join(__dirname, 'img', name)
outPath = (name) -> path.join(__dirname, 'artifacts', name)
fileNoExt = (name) -> path.basename name, path.extname(name)
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

  test "creates report", (t) ->
    artifactRows = artifacts.map (a) -> "<tr><td><img src='#{a.path}'></td><td>#{a.name}</td></tr>"
    artifactTable = [
      "<table border='1'>",
      artifactRows.join("\n"),
      "</table>"
    ].join("\n")

    content = [
      "<html><head><title>Artifacts</title></head><body>",
      artifactTable,
      "</body></html>"].join("\n")
    fs.writeFileSync(outPath("index.html"), content)
    t.end()

  troot.end()
