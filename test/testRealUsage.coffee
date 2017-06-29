test  = require 'tape'
sinon = require 'sinon'
gm    = require 'gm'
fs    = require 'fs'
path  = require 'path'

EmojiProcessor = require '../src/emojiProcessor'
ImageContainer = require '../src/imageContainer'
ImageResult    = require '../src/imageResult'
ImageWorker    = require '../src/imageWorker'
EmojiStore     = require '../src/emojiStore'

defaultMacros = require '../src/defaultMacros'

# shorthand for filenames
inPath  = (name) -> path.join(__dirname, 'img', name)
outPath = (name) -> path.join(__dirname, 'artifacts', name)

# removes extension from filename
fileNoExt = (name) -> path.basename name, path.extname(name)

# input images we've defined
baseEmoji =
  poop     : inPath 'dancingpoop.gif'
  bob      : inPath 'bob.png'
  chloe    : inPath 'chloe.gif'
  muscle   : inPath 'muscle-right.png'
  rage1    : inPath 'rage1.gif'
  rage1_id : inPath 'identity-rage1.gif'
  kamina   : inPath 'kamina_glasses.png'
  flux     : inPath 'flux_capacitor_128.gif'

# make a fake emoji store that works on our on-disk custom emoji
emojiFetchFn = (cb) ->
  cb null, baseEmoji
fakeEmojiStore = new EmojiStore(emojiFetchFn, 0)
fakeEmojiStore.workFnUrl = (desired) ->
  return (argsWhichArePaths, onComplete) ->
    ic = new ImageContainer(baseEmoji[desired], () -> {})
    ir = new ImageResult([], [], ic)
    onComplete(ir)

allMacros = require '../src/defaultMacros'

test "Real uses", (troot) ->

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
  testInput = (input, outputSuffix) ->
    test input, (t) ->
      ep = new EmojiProcessor(fakeEmojiStore, allMacros)
      ep.process input, (slackResp) ->
        t.equal(slackResp.message, null, "no error message")
        t.ok(slackResp.imgResult, "image result exists")
        t.ok(slackResp.imgResult.imgPath(), "image result path exists")
        t.ok(slackResp.fileDesc, "fileDesc exists")
        createArtifact(slackResp.imgResult.imgPath(), slackResp.fileDesc)
        #slackResp.cleanup()
        #t.deepEqual(value for own _, value of ImageContainer.activeContainers(), [])
        t.end()

  testInput "identity(:poop:)", ".gif"
  testInput "identity_gm(:poop:)", ".gif"
  testInput "firstframe(:poop:)", ".gif"
  testInput "lastframe(:poop:)", ".gif"
  testInput "dealwithit(:rage1:)", ".gif"
  testInput "dealwithit(:bob:)", ".gif"
  testInput "dealwithit(:rage1_id:)", ".gif"
  testInput "dealwithit(:chloe:)", ".gif"
  testInput "dealwithit(:rage1:, :kamina:)", ".gif"
  testInput "dealwithit(:rage1_id:, :kamina:)", ".gif"
  testInput "dealwithit(dealwithit(:rage1_id:), :kamina:)", ".gif"
  testInput "splosion(:rage1:)", ".gif"
  testInput "splosion(:rage1_id:)", ".gif"
  testInput "splosion(:bob:)", ".gif"
  testInput "splosion(:poop:)", ".gif"
  testInput "splosion(:flux:)", ".gif"
  testInput "intensifies(:rage1:)", ".gif"
  testInput "intensifies(:rage1_id:)", ".gif"
  testInput "intensifies(:poop:)", ".gif"

  # show the original just for comparison purposes, then the actual skintones
  testInput "identity(:muscle:)", ".gif"
  for num in [1..6]
    do (num) -> testInput "skintone_#{num}(:muscle:)", ".png"

  # generate HTML report from all those outputs
  test "creates report", (t) ->
    style = "style='background-color:grey;'"
    artifactRows = artifacts.map (a) -> "<tr><td #{style}><img src='#{a.path}'></td><td>#{a.name}</td></tr>"

    content = [
      "<html><head><title>End to EndArtifacts</title></head><body>",
      "<table border='1'>",
      artifactRows.join("\n"),
      "</table>",
      "</body></html>"].join("\n")
    fs.writeFileSync(outPath("e2e.html"), content)
    t.end()

  troot.end()
