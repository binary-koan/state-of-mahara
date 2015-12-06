Checker = require './checker'
model = require './model'

globToRegExp = require 'glob-to-regexp'

argv = require('yargs')
  .usage('Usage: $0 [options] [<pattern>]')
  .boolean('u')
  .alias('u', 'update')
  .describe('f', 'Clone the latest Mahara instead of using the last set of results')
  .help('help')
  .argv

if argv._.length > 0
  filenameRegex = globToRegExp(argv._[0])

displayIssues = (files) ->
  for filename in Object.keys(files).sort()
    break if !filenameRegex || !filenameRegex.test(filename)

    console.log(filename)
    for error in files[filename]
      console.log("  Line #{error.line}: #{error.message}")
    console.log("")

Checker.run forceUpdate: argv.update, callback: (data) ->
  if data.error
    console.log("Failed: #{data.error}")
  else if data.progress
    console.log(data.progress)
  else if data.complete
    model.findData data.revision, displayIssues
