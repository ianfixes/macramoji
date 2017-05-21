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

  nextFetchCountdown: ->
    min(0, @timestamp - @nextFetchOpportunity)

  nextFetchOpportunity: ->
    @lastFetch + EMOJI_FETCH_INTERVAL_SECONDS * 1000

  canFetchEmojiAgain: ->
    @nextFetchCountdown == 0

  fetchEmoji: (callback) ->
    # TODO: function that returns an error'd image result
    return unless canFetchEmojiAgain
    # do something with callback
    @lastFetch = @timestamp
    true

  updateStore: (emojiUrls) ->
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

  # preferred external entry point
  getEmoji: (desired, callback) ->
    # if all desired emoji

module.exports = EmojiStore
