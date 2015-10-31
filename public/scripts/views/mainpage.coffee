m = require 'mithril'

BaseView = require './base'
mainLayout = require './layout'

class SocketManager
  constructor: ({ listen }) ->
    @_socket = io.connect(window.location.href)
    for event in listen
      fn = 'on' + event.substr(0, 1).toUpperCase() + event.substr(1)
      @_socket.on event, @[fn].bind(this)

  emit: (event, data) ->
    @_socket.emit event, data

class DataManager extends SocketManager
  constructor: (controller) ->
    super listen: [ 'failed', 'progress', 'ready', 'checkers', 'data' ]
    @_controller = controller

    @_revision = null
    @_checkers = {}
    @_current = { checker: null, data: null }

  revision: -> @_revision
  checkers: -> Object.keys(@_checkers)
  count: (checker) -> @_checkers[checker]
  data: (checker) ->
    if @_current.checker == checker && @_current.data
      @_current.data
    else
      []

  load: (checker) -> @emit 'load', { checker }
  clearCurrentData: -> @_current = { checker: null, data: null }

  onFailed: ({ error }) ->
    @_controller.handleFail(error)

  onProgress: ({ progress }) ->
    @_controller.handleProgress(progress)

  onReady: ({ revision }) ->
    console.log('revision: ' + revision)
    @_revision = revision
    @emit 'getCheckers'
    @_controller.update()

  onCheckers: ({ checkers }) ->
    @_checkers = checkers
    @_controller.update()

  onData: ({ checker, data }) ->
    @_current = { checker, data }
    @_controller.update()

module.exports =
class MainPage extends BaseView
  constructor: ->
    super mainLayout

    @_data = new DataManager(this)
    @_data.emit 'getLatest'
    @_vm =
      error: null
      progress: 'Waiting for connection'
      toggleGroup: (checker) =>
        if @_data.data(checker).length
          @_data.clearCurrentData()
          @update()
        else
          @_data.load(checker)

  handleFail: (error) ->
    @_vm.error = error
    @update()

  handleProgress: (progress) ->
    @_vm.progress = progress
    @update()

  update: -> m.redraw()

  content: ->
    checkers = @_data.checkers()
    byFile = (o1, o2) -> o1.file.localeCompare(o2.file)

    if @_vm.error
      m '.message.error', @_vm.error
    else if !checkers.length
      m '.message.progress', @_vm.progress
    else
      [
        m 'h1', @_data.revision()
        checkers.sort().map (checker) =>
          [
            m 'button.accordion-header', onclick: @_vm.toggleGroup.bind(null, checker), [
              m('span', checker), m('span.badge', @_data.count(checker))
            ]
            m 'ul.data', @_data.data(checker).sort(byFile).map (item) ->
              m 'li', JSON.stringify(item)
          ]
      ]
