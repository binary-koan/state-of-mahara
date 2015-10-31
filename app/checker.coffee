{ exec } = require 'child_process'
fs = require 'fs'
{ assign, attempt, isArray, isError } = require 'lodash'
path = require 'path'
request = require 'request'
rimraf = require 'rimraf'
{ walk } = require 'walk'

model = require './model'

MAHARA_DIR = path.resolve("#{model.DATAROOT}/mahara")

module.exports =
class Checker
  @instance: null

  @getLatestResults: (callbacks) ->
    callbacks = [callbacks] unless isArray(callbacks)
    model.findLatestRevision (rev) ->
      model.findData rev, (data) ->
        if data
          callback(data) for callback in callbacks
        else
          Checker.update(callbacks)

  @update: (callbacks) ->
    callbacks = [callbacks] unless isArray(callbacks)
    if Checker.instance && !Checker.instance.complete
      Checker.instance.addCallbacks(callbacks)
    else
      Checker.instance = new Checker(callbacks)

  constructor: (callbacks) ->
    @_callbacks = callbacks
    @_data = []
    @_start()

  addCallbacks: (callbacks) ->
    @_callbacks = @_callbacks.concat callbacks

  _start: ->
    request {
      url: 'https://api.github.com/repos/MaharaProject/mahara/git/refs/heads/master'
      headers: { 'User-Agent': 'request' }
    }, (err, response, body) =>
      result = attempt(JSON.parse, body)
      if isError(result)
        @_finish(error: 'Error parsing JSON: ' + result)

      @_checkRevision(result)

  _checkRevision: (result) ->
    @_revision = result.object?.sha
    if not @_revision
      @_finish(error: 'Request for latest revision failed')
    else if @_alreadyClonedRevision()
      @_checkCurrentClone()
    else
      @_cloneLatest => @_checkCurrentClone()

  _cloneLatest: (callback) ->
    rimraf MAHARA_DIR, =>
      @_invokeCallbacks(progress: 'Cloning Mahara')

      exec "git clone --depth 1 https://github.com/MaharaProject/mahara.git #{MAHARA_DIR}", (err, stdout, stderr) =>
        if err
          @_invokeCallbacks(error: "git clone failed. STDOUT #{stdout}; STDERR #{stderr}")
        else
          callback()

  _alreadyClonedRevision: ->
    filename = "#{MAHARA_DIR}/.git/refs/heads/master"
    fs.existsSync(filename) && fs.readFileSync(filename, 'utf8') == @_revision

  _checkCurrentClone: ->
    checkers =
      mochikit: require('./checker/mochikit')
    walker = walk MAHARA_DIR, followLinks: false

    files = 0
    walker.on 'file', (root, stats, next) =>
      fs.readFile path.join(root, stats.name), 'utf8', (err, contents) =>
        filename = path.join(root, stats.name).replace MAHARA_DIR, ''
        for name, checker of checkers
          @_addData name, filename, checker(stats, contents)

        files += 1
        @_invokeCallbacks(progress: "Scanning file #{files}")
        next()

    walker.on 'end', =>
      model.save @_revision, @_data, @_finish.bind(this, @_data)

  _addData: (checker, filename, result) ->
    if result && result.length > 0
      for item in result
        @_data.push assign({ checker: checker, file: filename }, item)

  _invokeCallbacks: (data) ->
    console.log(@_callbacks)
    callback(data) for callback in @_callbacks

  _finish: (data) ->
    @_invokeCallbacks data
    @_complete = true
