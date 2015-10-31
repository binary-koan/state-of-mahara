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

  checkers: -> Object.keys(@_checkers)
  count: (checker) -> @_checkers[checker]
  data: (checker) -> @_current.checker == checker && @_current.data

  load: (checker) -> @emit 'load', { checker }

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

  handleFail: (error) ->
    @_vm.error = error
    update()

  handleProgress: (progress) ->
    @_vm.progress = progress
    update()

  update: -> m.redraw()

  content: ->
    checkers = @_data.checkers()

    if @_vm.error
      m '.message.error', @_vm.error
    else if !checkers.length
      m '.message.progress', @_vm.progress
    else
      checkers.map (checker) =>
        data = @_data.data(checker) || []

        [
          m 'button.block', onclick: @_data.load.bind(@_data, checker), [
            checker, m('span.count', @_data.count(checker))
          ]
          m 'ul.data', data.map (item) ->
            m 'li', JSON.stringify(item)
        ]
