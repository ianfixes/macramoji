gm  = require 'gm'
fs = require 'fs'

# container class
# mostly to make unit testing easier
class SlackResponse
  constructor: () ->
    @message = null
    @imgResult = null
    @fileName = null
    @fileDesc = null

  setMessage: (msg) ->
    @message = msg

  setUpload: (imgResult, fileDesc) ->
    @imgResult = imgResult
    @fileDesc = fileDesc

  respondBotkit: (payload, bot, webApi) ->
    bot.replyPrivate @message if @message
    @imgResult && @uploadBotkit bot, payload.channel, @imgResult.imgPath(), @fileDesc, () =>
      @imgResult.cleanup()

  respondHubot: (slackResponseObject) ->
    slackResponseObject.send @message if @message
    @imgResult && @uploadHubot slackResponseObject, @imgResult.imgPath(), @fileDesc, () =>
      @imgResult.cleanup()

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


module.exports = SlackResponse
