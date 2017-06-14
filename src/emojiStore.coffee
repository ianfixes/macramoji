fs = require 'fs'
tmp = require 'tmp'
http = require 'http'
https = require 'https'
urllib = require 'url'

ImageResult = require './imageResult'

# We need to get the emoji from Slack via their client.
# Try to stay up to date, but don't go nuts.
class EmojiStore
  constructor: (@slackClient, fetchIntervalSeconds) ->
    @store = {}
    @timer = null
    @fetchEmoji()
    @setFetchInterval(fetchIntervalSeconds)

  fetchEmoji: (onComplete) =>
    @slackClient.emoji.list (err, result) =>
      console.log "emoji.list got #{Object.keys(result.emoji).length} emoji)"
      @updateStore(result.emoji)
      onComplete() if onComplete?

  setFetchInterval: (seconds) ->
    clearInterval(@timer) if @timer?
    return if seconds == 0
    return if seconds == undefined
    return unless seconds?
    @timer = setInterval fetchEmoji, seconds * 1000

  known: () ->
    Object.keys @store

  hasEmoji: (name) ->
    name of @store

  updateStore: (emojiUrls) =>
    alias = 'alias:'
    handleUrl = (url) ->
      if url.indexOf(alias) != 0
        {url: url}
      else
        {alias: url.substr(alias.length)}

    @store = {}
    for name, url of emojiUrls
      data = handleUrl(url)
      if "url" of data
        @store[name] = data.url
      else
        @store[name] = emojiUrls[data.alias]

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

  # a function for an ImageWorker
  workFn: (desired) ->
    url = @store[desired]
    # callback takes error or null
    initImageResultByDownloading = (path, callback) =>
      @download url, path, (err) ->
        callback(err)

    # onComplete takes an ImageResult
    return (argsWhichArePaths, onComplete) ->
      ImageResult.initFromNewTempFile initImageResultByDownloading, (result) ->
        onComplete(result)


module.exports = EmojiStore
