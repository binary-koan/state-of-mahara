{ exec } = require 'child_process'
fs = require 'fs'
{ assign, attempt, isArray } = require 'lodash'
path = require 'path'
request = require 'request'
rimraf = require 'rimraf'
{ walk } = require 'walk'

model = require './model'

MAHARA_DIR = "#{model.DATAROOT}/mahara"

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
    if Checker.instance
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
      sha = attempt(JSON.parse(body))?.object?.sha
      @_cloneAndCheck(sha || error: 'Request for latest revision failed')

  _cloneAndCheck: (revision, callback) ->
    if @_alreadyClonedRevision(revision)
      @_checkCurrentClone()
      return

    rimraf MAHARA_DIR, =>
      @_invokeCallbacks(progress: 'Cloning Mahara')

      exec "git clone --depth 1 https://github.com/MaharaProject/mahara.git #{MAHARA_DIR}", (err, stdout, stderr) =>
        if err
          @_invokeCallbacks(error: "git clone failed. STDOUT #{stdout}; STDERR #{stderr}")
        else
          @_checkCurrentClone()

  _alreadyClonedRevision: (revision) ->
    fs.readFileSync("#{MAHARA_DIR}/.git/refs/heads/master", 'utf8') == revision

  _checkCurrentClone: ->
    checkers =
      mochikit: require('./checker/mochikit')
    walker = walk MAHARA_DIR, followLinks: false

    files = 0
    walker.on 'file', (root, stats, next) =>
      fs.readFile path.join(root, stats.name), 'utf8', (err, contents) =>
        filename = path.join(root, stats.name).replace MAHARA_DIR, ''
        for name, checker of checkers
          @_addData name, checker(stats, contents)

        files += 1
        @_invokeCallbacks(progress: "Scanning file #{files}")
        next()

    walker.on 'end', =>
      model.save revision, @_data, @_invokeCallbacks.bind(this, data)

  _addData: (name, result) ->
    if result.length > 0
      for item in result
        @_data.push assign({ checker: name, file: filename }, item)

  _invokeCallbacks: (data) ->
    console.log(@_callbacks)
    callback(data) for callback in @_callbacks
