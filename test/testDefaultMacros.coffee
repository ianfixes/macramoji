test  = require 'tape'
sinon = require 'sinon'
gm    = require 'gm'
fs    = require 'fs'
path  = require 'path'

defaultMacros = require '../src/defaultMacros'

# shorthand for filenames
inPath  = (name) -> path.join(__dirname, 'img', name)
outPath = (name) -> path.join(__dirname, 'artifacts', name)

# removes extension from filename
fileNoExt = (name) -> path.basename name, path.extname(name)

# input images we've defined
poop     = inPath 'dancingpoop.png'
bob      = inPath 'bob.png'
chloe    = inPath 'chloe.gif'
muscle   = inPath 'muscle-right.png'
rage1    = inPath 'rage1.gif'
rage1_id = inPath 'identity-rage1.gif'
kamina   = inPath 'kamina_glasses.png'

test "defaultMacros", (troot) ->

  artifacts = []

  # keep a list of outputs we've made
  createArtifact = (inputPath, filename) ->
    outputPath = outPath(filename)
    fs.createReadStream(inputPath).pipe(fs.createWriteStream(outputPath))
    artifacts.push
      name: fileNoExt(filename)
      path: filename

  # do an entire image-generation test.  we can't programmatically check the outputs (well, anything's possible
  #   but we're really not ready for pixel & encoding perfection here), so we just run tests and keep track of
  #   the outputs -- for inclusion in an overall summary later
  testMacro = (macro, label, inputs, outputSuffix) ->
    fullLabel = macro
    fullLabel = if label == "" then macro else "#{macro} #{label}"
    test fullLabel, (t) ->
      if !(macro of defaultMacros)
        t.fail("#{macro} contained in #{JSON.stringify(Object.keys(defaultMacros))}")
        return t.end()
      defaultMacros[macro] inputs, (result) ->
        createArtifact(result.imgPath(), "#{macro}#{outputSuffix}")
        t.end()

  testMacro "identity", "", [poop], ".gif"
  testMacro "identity_gm", "", [poop], ".gif"
  testMacro "firstframe", "", [poop], ".gif"
  testMacro "lastframe", "", [poop], ".gif"
  testMacro "dealwithit", "single arg", [rage1], "_default_glasses.gif"
  testMacro "dealwithit", "single arg no alpha channel", [bob], "_noalpha_default_glasses.gif"
  testMacro "dealwithit", "single arg glasses too big", [rage1_id], "_default_glasses_resized.gif"
  testMacro "dealwithit", "single arg animation", [chloe], "_animation.gif"
  testMacro "dealwithit", "double arg", [rage1, kamina], "_kamina_glasses.gif"
  testMacro "dealwithit", "double arg glasses too big", [rage1_id, kamina], "_kamina_glasses_resized.gif"
  testMacro "splosion", "from static image", [rage1], "_static.gif"
  testMacro "splosion", "from static small image", [rage1_id], "_static_small.gif"
  testMacro "splosion", "from static image no alpha", [bob], "_static_noalpha.gif"
  testMacro "splosion", "from animated image", [poop], "_from_animated.gif"
  testMacro "intensifies", "", [rage1], "_big.gif"
  testMacro "intensifies", "from smaller image", [rage1_id], "_small.gif"
  testMacro "intensifies", "from animation", [poop], "_animated.gif"

  # show the original just for comparison purposes, then the actual skintones
  testMacro "identity", "muscle", [muscle], "_muscle.gif"
  for num in [1..6]
    do (num) -> testMacro "skintone_#{num}", "fitzpatrick", [muscle], ".png"

  # generate HTML report from all those outputs
  test "creates report", (t) ->
    style = "style='background-color:grey;'"
    artifactRows = artifacts.map (a) -> "<tr><td #{style}><img src='#{a.path}'></td><td>#{a.name}</td></tr>"

    content = [
      "<html><head><title>Artifacts</title></head><body>",
      "<table border='1'>",
      artifactRows.join("\n"),
      "</table>",
      "</body></html>"].join("\n")
    fs.writeFileSync(outPath("index.html"), content)
    t.end()

  troot.end()
