http = require 'http'
fs = require 'fs'
tmp = require 'tmp'
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
    @slackClient.emoji (err, result) =>
      @updateStore(result)
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
    parseUrl = (url) ->
      if url.indexOf(alias) != 0
        {url: url}
      else
        {alias: url.substr(alias.length)}

    @store = {}
    for name, url of emojiUrls
      data = parseUrl(url)
      if "url" of data
        @store[name] = data.url
      else
        @store[name] = emojiUrls[data.alias]

  download: (url, dest, cb) ->
    file = fs.createWriteStream(dest)
    request = http.get(url, (response) ->
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
