fs = require 'fs'
http = require 'http'
https = require 'https'
urllib = require 'url'
builtIn = require 'emoji-datasource-apple'

path = require 'path'
getInstalledPath = require 'get-installed-path'

ImageResult = require './imageResult'
ImageContainer = require './imageContainer'

spritePath = (filename) ->
  eda = getInstalledPath.sync('emoji-datasource-apple', {local: true})
  path.join(eda, 'img', 'apple', '64', filename)

slackEmoji = {}
for e in builtIn when e.has_img_apple
  for short_name in e.short_names
    slackEmoji[short_name] = spritePath(e.image)

# We need to get the emoji from Slack via their client.
# Try to stay up to date, but don't go nuts.
class EmojiStore
  # emojiFetchFn takes a callback (err, result)
  #   where result is is a { short_name: URL } dictionary
  constructor: (@emojiFetchFn, fetchIntervalSeconds) ->
    @urls = {}
    @timer = null
    @builtIn = slackEmoji
    @fetchEmoji()
    @setFetchInterval(fetchIntervalSeconds)


  fetchEmoji: (onComplete) =>
    @emojiFetchFn (err, result) =>
      console.log "fetchEmoji's emojiFetchFn got #{Object.keys(result).length} emoji"
      @updateUrls(result)
      onComplete() if onComplete?

  addEmoji: (name, url) =>
    @urls[name] = url

  deleteEmoji: (name) =>
    delete @urls[name]

  setFetchInterval: (seconds) =>
    clearInterval(@timer) if @timer?
    return if seconds == 0
    return if seconds == undefined
    return unless seconds?
    @timer = setInterval @fetchEmoji, seconds * 1000

  known: () ->
    ret = {}
    for x in Object.keys(@urls).concat(Object.keys(@builtIn))
      ret[x] = true
    ret

  hasEmoji: (name) ->
    (name of @urls) || (name of @builtIn)

  updateUrls: (emojiUrls) =>
    alias = 'alias:'
    handleUrl = (url) ->
      if url.indexOf(alias) != 0
        {url: url}
      else
        {alias: url.substr(alias.length)}

    @urls = {}
    for name, url of emojiUrls
      data = handleUrl(url)
      if "url" of data
        @urls[name] = data.url
      else
        @urls[name] = emojiUrls[data.alias]

  download: (srcUrl, dest, cb) ->
    file = fs.createWriteStream(dest)
    ht = if urllib.parse(srcUrl).protocol == "https:" then https else http
    request = ht.get(srcUrl, (response) ->
      response.pipe(file)
      file.on 'finish', () ->
        file.close(cb);  # close() is async, call cb after close completes.
    ).on('error', (err) -> # Handle errors
      # fs.unlink dest  # Delete the file async. (But we don't check the result)
      cb(err.message)
    )

  # a function for use in an ImageWorker
  workFn: (desired) =>
    return @workFnUrl(desired) if desired of @urls
    return @workFnFile(desired) if desired of @builtIn

  # a function for an ImageWorker when file is local
  workFnFile: (desired) ->
    file = @builtIn[desired]
    return (argsWhichArePaths, onComplete) ->
      onComplete(new ImageResult([], [], new ImageContainer(file, () -> )))

  # a function for an ImageWorker when file is remote
  workFnUrl: (desired) ->
    url = @urls[desired]
    # callback takes error or null
    initImageResultByDownloading = (path, callback) =>
      @download url, path, (err) ->
        callback(err)

    # onComplete takes an ImageResult
    return (argsWhichArePaths, onComplete) ->
      ImageResult.initFromNewTempFile initImageResultByDownloading, (result) ->
        onComplete(result)


module.exports = EmojiStore
