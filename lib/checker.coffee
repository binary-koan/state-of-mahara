{ exec } = require 'child_process'
fs = require 'fs'
{ assign, attempt, isArray, isError } = require 'lodash'
path = require 'path'
{ walk } = require 'walk'

model = require './model'
checkers = require './checker/index'

module.exports =
class Checker
  @instance = null

  @run: (config) ->
    new Checker(config).run()

  constructor: ({ path, forceUpdate, callback }) ->
    @_path = path
    @_options = { forceUpdate }
    @_callback = callback

  run: ->
    @_findRevision (revision) =>
      @_revision = revision.trim()

      if @_options.forceUpdate
        @_checkRevision()
      else
        @_checkExistingData()

  _findRevision: (callback) ->
    exec "cd #{@_path} && git log --format=%H -n 1 HEAD", (err, stdout, stderr) =>
      callback(stdout)

  _checkExistingData: ->
    if model.hasData(@_revision)
      @_finish()
    else
      @_checkRevision(@_revision)

  _checkRevision: ->
    exec "cd #{@_path} && git log --format=%H -n 1 HEAD", (err, stdout, stderr) =>
      @_commitMessage = stdout
      @_runChecker()

  _runChecker: ->
    walker = walk @_path, followLinks: false

    files = 0
    fileCallback = (next) =>
      files += 1
      if files % 100 == 0
        => @_callback(progress: "Scanning ... #{files} files checked"); next()
      else
        next

    walker.on 'file', (root, stats, next) =>
      fs.readFile path.join(root, stats.name), 'utf8', (err, contents) =>
        filename = path.join(root, stats.name).replace(@_path, '').replace(/\\/g, '/')
        for name, checker of checkers
          @_addData name, filename, checker(stats, contents), fileCallback(next)

    walker.on 'end', @_finish.bind(this)

  _addData: (checker, filename, result, callback) ->
    if result && result.length > 0
      data = []
      for item in result
        data.push assign({ checker: checker, file: filename }, item)
      model.save @_revision, data, callback
    else
      callback()

  _finish: (err) ->
    if err
      @_callback error: err
    else
      @_callback complete: true, revision: @_revision, message: @_commitMessage
    @_complete = true
