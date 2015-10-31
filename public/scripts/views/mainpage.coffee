m = require 'mithril'

AbstractWorker = require '../util/worker'
BaseView = require './base'
mainLayout = require './layout'

class DataManager extends AbstractWorker
  constructor: ->
    super new Worker('/worker.js')
    @_checkers = []
    @_currentChecker = null
    @_currentData = null

    @_dataLoadedCallback = null

  checkers: -> @_checkers
  currentChecker: -> @_currentChecker
  currentData: -> @_currentData

  dataLoaded: (data) ->
    @postMessage 'dataLoaded', { data }

  getData: (checker, callback) ->
    @_dataLoadedCallback = callback
    @postMessage 'getData', checker: checker

  onDatabaseReady: ({ checkers }) ->
    @_checkers = checkers
    m.redraw()

  onData: ({ checker, data }) ->
    @_currentData = data
    @_dataLoadedCallback() if @_dataLoadedCallback

module.exports =
class MainPage extends BaseView
  constructor: ->
    super mainLayout
    @worker = new Worker('/worker.js')

    @error = null
    @progress = 'Waiting for connection'
    @dataManager = new DataManager()

    @openChecker = null
    @setOpenChecker = (checker) ->
      @openChecker = checker
      @dataManager.getData checker, -> m.redraw()

    socket = io.connect window.location.href

    socket.on 'failed', (data) =>
      @error = data.error || 'Unspecified error'
      m.redraw()

    socket.on 'progress', (data) =>
      @progress = data.progress
      m.redraw()

    socket.on 'data', (data) =>
      @dataManager.dataLoaded data

  content: ->
    checkers = Array.from(@dataManager.checkers())

    [
      if @error
        m '.error', @error
      else if !checkers.length
        m '.progress', @progress

      checkers.map (checker) => [
        m 'button', { onclick: @setOpenChecker.bind(this, checker) }, checker
        if checker == @openChecker && @dataManager.currentData()
          m 'ul', @dataManager.currentData().map (item) ->
            m 'li', JSON.stringify(item)
      ]
    ]
