gm  = require 'gm'
fs = require 'fs'

# container class
# mostly to make unit testing easier
class SlackResponse
  constructor: () ->
    @message = null
    @imgResult = null
    @fileDesc = null

  cleanup: =>
    @imgResult && @imgResult.cleanup()

  setMessage: (msg) ->
    @message = msg

  setUpload: (imgResult, fileDesc) ->
    @imgResult = imgResult
    @fileDesc = fileDesc

  respondBotkit: (payload, bot, webApi) =>
    bot.replyPrivate @message if @message
    @imgResult && @uploadBotkit bot, payload.channel, @imgResult.imgPath(), @fileDesc, () =>
      @cleanup()

  respondHubot: (slackResponseObject) =>
    slackResponseObject.send @message if @message
    @imgResult && @uploadHubot slackResponseObject, @imgResult.imgPath(), @fileDesc, () =>
      @cleanup()

  replyPrivateBB: (respondFn, text, onComplete) ->
    respondFn
      text: text,
      response_type: "ephemeral"
    , (err, data) ->
      onComplete() if onComplete

  respondBeepBoopSlashCommand: (channelId, bot, respondFn) =>
    if @message
      @replyPrivateBB respondFn, @message, @cleanup
    else if @imgResult
      # WE APPARENTLY DO NOT NEED ACK { reponse_type: in_channel } IN THIS FRAMEWORK
      @uploadBeepBoop(channelId, bot, respondFn, @cleanup)


  uploadBotkit: (bot, channel, filename, label) ->
    gm(@imgResult.imgPath()).format (err, fmt) =>
      format = if err then 'gif' else fmt

      bot.api.files.upload
        title: @fileDesc,
        filename: "#{@fileDesc}.#{format}",
        filetype: format,
        channels: channel,
        file: fs.createReadStream(@imgResult.imgPath()),
      , (err, resp) =>
        console.log("upload got: #{err} #{JSON.stringify(err)} #{JSON.stringify(resp)}")
        @imgResult.cleanup()

  uploadHubot: (slackResponseObject, filename, label, onComplete) ->
    robot = slackResponseObject.robot
    # slack API for file.upload

    # get upload type and go
    gm(filename).format (err, fmt) ->
      format = if err then 'gif' else fmt
      contentOpts =
          #content: fs.readFileSync(tmpPath), # doesn't work with binary
          file: fs.createReadStream(filename)
          channels: slackResponseObject.message.room,
          fileType: format # TODO: figure it out

      robot.adapter.client.web.files.upload "#{label}.#{format}", contentOpts, (fileUploadErr, resp) ->
        console.log(resp)
        onComplete()

  uploadBeepBoop: (channelId, bot, respondFn, onComplete) =>
    path = @imgResult.imgPath()
    gm(path).format (err, fmt) =>
      format = if err then 'gif' else fmt
      fileName = @fileDesc + "." + format

      streamOpts =
        file: fs.createReadStream(path),
        title: @fileDesc,
        filetype: format,
        channels: channelId,

      bot.files.upload fileName, streamOpts, (err, res) =>
        # if (err) console.log("bot.files.upload err: " + JSON.stringify(err, null, 2));
        # console.log("bot.files.upload res: " + JSON.stringify(res, null, 2));

        if res.error == "invalid_channel"
          @replyPrivateBB respondFn, "I can't upload here.  Try this in a public channel or, DM me."

        onComplete() if onComplete

module.exports = SlackResponse
