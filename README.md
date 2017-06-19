# Macramoji
[![npm version](https://badge.fury.io/js/macramoji.svg)](https://badge.fury.io/js/macramoji)
[![Build Status](https://travis-ci.org/ifreecarve/macramoji.svg)](https://travis-ci.org/ifreecarve/macramoji)

A slack-centric programming language for altering emoji

# How it works

Macramoji parses a simple functional programming language for emoji, where function names can either precede or follow the parenthesis and emoji are slack-style (i.e. beginning and ending with a `:`).  For example:

```
(dealwithit(:rage1:, :kamina-glasses:))splosion
```

This produces the following gif (assuming you have `kamina-glasses`):

![dealwithit-rage1-kamina-glasses-splosion](doc/dealwithit-rage1-kamina-glasses-splosion.gif)


# Reference Implementation: Hubot script

This script allows you to message a hubot instance with the command `emojify (dealwithit(:rage1:, :kamina-glasses:))splosion`

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

# Defining Your Own Functions

Arbitrary emoji-processing functions are straightforward to add; they are GraphicsMagick (or ImageMagick) scripts.  Their input arguments will be an array of paths and a callback function.  The callback takes a single parameter -- an `ImageResult`.  The `ImageResult` conveys the result (if successful), any error messages (if unsuccessful) and a set of `ImageContainer` objects for any temporary files created during the processing that would need to be cleaned up later.

### What Macramoji guarantees

* your function will only be called if the input arguments successfully resolve to ImageResults
* all input image arguments will automatically be rescaled to the size of the smallest image


### What Macramoji does not guarantee

* input animations may need to be `coalesce`d
* no alpha channel is explicitly provided
* your function may not receive all the arguments it expects (in which case, you should return an `ImageResult` that holds an error message)


A basic exaple is `greyscale` which converts an emoji to greyscale:

```coffee
imageTransform = (require 'macramoji').imageTransform

greyscaleMacro = (paths, callback) ->
  greyWorkFn = (inputGmObject) ->
    inputGmObject.modulate(100, 0) # http://aheckmann.github.io/gm/docs.html#modulate
  imageTransform.resultFromGM gm(paths[0]), greyWorkFn, callback

# assume processor = new macramoji.EmojiProcessor as above
processor.addMacro("greyscale", greyscaleMacro)
```

You are encouraged to [contribute](CONTRIBUTING.md) functions that you write back to this project by adding them to `defaultMacros.coffee`.


# TODO

* Check that proper cleanup is happening
* Enable slack reponses without hubot
