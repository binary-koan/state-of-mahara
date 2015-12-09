Checker = require './checker'
model = require './model'

argv = require('yargs')
  .usage('Usage: $0 [options] <path/to/mahara> [<filter/pattern>]')
  .demand(1)
  .boolean('u')
  .alias('u', 'update')
  .describe('u', 'Delete any old data for this revision and rebuild')
  .help('help')
  .argv

maharaPath = argv._[0]

if argv._.length > 1
  filenameRegex = new RegExp(
    argv._[1]
      .replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
      .replace("\\/\\*\\*\\/", "\\/.*")
      .replace("\\*", "[^\\/]*")
  )

displayIssues = (files) ->
  for filename in Object.keys(files).sort()
    continue if filenameRegex && !filenameRegex.test(filename)

    console.log(filename)
    for error in files[filename]
      console.log("  Line #{error.line}: #{error.message}")
    console.log("")

new Checker(path: maharaPath, forceUpdate: argv.update, callback: (data) ->
  if data.error
    console.log("Failed: #{data.error}")
  else if data.progress
    console.log(data.progress)
  else if data.complete
    model.findData data.revision, displayIssues
).run()
