m = require 'mithril'

BaseView = require './base'
mainLayout = require './layout'

module.exports =
class MainPage extends BaseView
  constructor: ->
    super mainLayout

    @error = null
    @progress = 'Waiting for connection'
    @data = null

    socket = io.connect window.location.href

    socket.on 'failed', (data) =>
      ctrl.error = data.error || 'Unspecified error'
      m.redraw()

    socket.on 'progress', (data) =>
      ctrl.progress = data.progress
      m.redraw()

    socket.on 'data', (data) =>
      ctrl.data = data
      m.redraw()

  content: (ctrl) ->
    if ctrl.data
      m 'pre',
        m 'code', JSON.stringify(ctrl.data, null, 2)
    else if ctrl.error
      m '.error', ctrl.error
    else
      m '.progress', "Loading ... #{ctrl.progress}"
