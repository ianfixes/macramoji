http = require 'http'
fs = require 'fs'
tmp = require 'tmp'
ImageResult = require './imageResult'
ImageContainer = require './imageContainer'

EMOJI_FETCH_INTERVAL_SECONDS = 300

# TODO: generate the "emoji download" action directly in here
# TODO: put the "retry after refetch" logic in here

# We need to get the emoji from Slack via their client.
# Try to stay up to date, but don't go nuts.
class EmojiStore
  constructor: (@slackClient) ->
    @lastFetch = 0
    @store = {}

  timestamp: ->
    (new Date).getTime()

  nextFetchCountdown: =>
    min(0, @timestamp() - @nextFetchOpportunity())

  nextFetchOpportunity: =>
    @lastFetch + EMOJI_FETCH_INTERVAL_SECONDS * 1000

  canFetchEmojiAgain: =>
    @nextFetchCountdown == 0

  fetchEmoji: (callback) =>
    # TODO: function that returns an error'd image result
    return unless canFetchEmojiAgain
    # do something with callback
    @lastFetch = @timestamp
    true

  known: () ->
    Object.keys @store

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
