module.exports = (stats, contents) ->
  return unless /\.php|js/.test stats.name

  results = []
  for line, i in contents.split(/\r|\r?\n/)
    if line.indexOf('getElementsByTagAndClassName') >= 0
      results.push line: i, function: 'getElementsByTagAndClassName'

  results
