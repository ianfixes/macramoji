# Macramoji
A slack-centric programming language for altering emoji

# Example

```coffee
macramoji = require 'macramoji'

refreshSeconds = 15 * 60 # refesh emoji list every 15 minutes
@emojiStore = new macramoji.EmojiStore(@hubotRobot.adapter.client.web, refreshSeconds)

@processor = new macramoji.EmojiProcessor(@emojiStore, macramoji.defaultMacros)

@hubotRobot.respond /go go emoji macro (.*)/i, (res) ->
  emojiStr = res.match[1].trim()
  @processor.process emojiStr, (slackResp) ->
    slackResp.respond(res)
```

# TODO

* Check that proper cleanup is happening
* Enable slack reponses without hubot
