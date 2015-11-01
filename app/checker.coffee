{ exec } = require 'child_process'
fs = require 'fs'
{ assign, attempt, isArray, isError } = require 'lodash'
path = require 'path'
request = require 'request'
rimraf = require 'rimraf'
{ walk } = require 'walk'

model = require './model'
checkers = require './checker/index'

MAHARA_DIR = path.resolve("#{model.DATAROOT}/mahara")

module.exports =
class Checker
  @instance = null

  @run: ({ forceUpdate, callback }) ->
    callbacks = [callback]
    if Checker.instance && !Checker.instance.complete
      Checker.instance.addCallbacks(callbacks)
    else
      Checker.instance = new Checker(callbacks, { forceUpdate })

  constructor: (callbacks, { forceUpdate }) ->
    console.log('Starting checker')
    @_callbacks = callbacks
    @_data = []

    if forceUpdate
      @_start()
    else
      @_checkLatest()

  addCallbacks: (callbacks) ->
    @_callbacks = @_callbacks.concat callbacks

  _checkLatest: ->
    model.findLatestRevision (rev) =>
      @_revision = rev

      model.hasData rev, (exists) =>
        if exists
          console.log('Data already exists')
          @_finish()
        else
          console.log('No data, rechecking')
          @_start()

  _start: ->
    request {
      url: 'https://api.github.com/repos/MaharaProject/mahara/git/refs/heads/master'
      headers: { 'User-Agent': 'request' }
    }, (err, response, body) =>
      result = attempt(JSON.parse, body)
      if isError(result)
        @_finish('Error parsing JSON: ' + result)

      @_checkRevision(result)

  _checkRevision: (result) ->
    @_revision = result.object?.sha
    console.log('Starting checker: ' + @_revision)

    if not @_revision
      @_finish('Request for latest revision failed')
    else if @_alreadyClonedRevision()
      @_checkCurrentClone()
    else
      @_cloneLatest @_checkCurrentClone.bind(this)

  _cloneLatest: (callback) ->
    rimraf MAHARA_DIR, =>
      console.log('Cloning Mahara')
      @_invokeCallbacks(progress: 'Cloning Mahara')

      exec "git clone --depth 1 https://github.com/MaharaProject/mahara.git #{MAHARA_DIR}", (err, stdout, stderr) =>
        if err
          @_invokeCallbacks(error: "git clone failed. STDOUT #{stdout}; STDERR #{stderr}")
        else
          callback()

  _alreadyClonedRevision: ->
    filename = "#{MAHARA_DIR}/.git/refs/heads/master"
    fs.existsSync(filename) && fs.readFileSync(filename, 'utf8').trim() == @_revision

  _checkCurrentClone: ->
    console.log('Checking clone')
    walker = walk MAHARA_DIR, followLinks: false

    files = 0
    fileCallback = (next) =>
      files += 1
      if files % 100 == 0
        => @_invokeCallbacks(progress: "Scanning ... #{files} files checked"); next()
      else
        next

    walker.on 'file', (root, stats, next) =>
      fs.readFile path.join(root, stats.name), 'utf8', (err, contents) =>
        filename = path.join(root, stats.name).replace MAHARA_DIR, ''
        for name, checker of checkers
          @_addData name, filename, checker(stats, contents), fileCallback(next)

    walker.on 'end', @_finish.bind(this)

  _addData: (checker, filename, result, callback) ->
    if result && result.length > 0
      console.log('Adding data: ' + filename)
      data = []
      for item in result
        data.push assign({ checker: checker, file: filename }, item)
      model.save @_revision, data, callback
    else
      callback()

  _invokeCallbacks: (data) ->
    callback(data) for callback in @_callbacks

  _finish: (err) ->
    console.log('Finishing: ' + err)
    if err
      @_invokeCallbacks error: err
    else
      @_invokeCallbacks complete: true, revision: @_revision
    @_complete = true
