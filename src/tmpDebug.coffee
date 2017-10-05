# sometimes we need to debug temp files.
# this is a mock that just puts them in the specified directory

path = require 'path'

class MockTmp
  constructor: (@basepath) ->
    @i = 0
    console.log("Mocking tmp module; files will be created in #{@basepath}")

  pad: (number, digits) ->
    # https://stackoverflow.com/a/10075654
    Array(Math.max(digits - String(number).length + 1, 0)).join(0) + number

  # mock the creation of a tmp file with detached descriptor
  # we don't clean it up.
  #    tmp.file { discardDescriptor: true }, (err, newPath, fd, cleanupCallback) ->
  file: (options, callback) =>
    prefix = options.prefix || "tmp-"
    postfix = options.postfix || ".tmp"
    filename = "#{prefix}MOCK#{@pad(@i++, 5)}#{postfix}"
    fullpath = path.join(@basepath, filename)
    callback(null, fullpath, null, () ->)

module.exports = MockTmp
