# Macramoji
A slack-centric programming language for altering emoji

# Reference Implementation: Hubot script

```coffee
macramoji = require 'macramoji'
refreshSeconds = 15 * 60 # refesh emoji list every 15 minutes
module.exports = (robot) ->
  emojiStore = new macramoji.EmojiStore(robot.adapter.client.web, refreshSeconds)
  processor = new macramoji.EmojiProcessor(emojiStore, macramoji.defaultMacros)

  robot.respond /emojify (.*)/i, (res) ->
    emojiStr = res.match[1].trim()
    processor.process emojiStr, (slackResp) ->
      slackResp.respond(res)
```

# TODO

* Check that proper cleanup is happening
* Enable slack reponses without hubot
