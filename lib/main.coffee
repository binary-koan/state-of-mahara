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
  issues = 0
  Object.keys(files).sort().forEach (filename) ->
    return if filenameRegex && !filenameRegex.test(filename)

    console.log(filename)
    
    errors = files[filename].sort (a, b) -> a.line - b.line
    errors.forEach (error) ->
      issues += 1
      console.log("  Line #{error.line}: #{error.message}")
    console.log("")

  console.log("#{issues} issues.")

Checker.run path: maharaPath, forceUpdate: argv.update, callback: (data) ->
  if data.error
    console.log("Failed: #{data.error}")
  else if data.progress
    console.log(data.progress)
  else if data.complete
    model.findData data.revision, displayIssues
