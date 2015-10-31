{ assign } = require 'lodash'

module.exports =
class AbstractWorker
  constructor: (worker) ->
    @_worker = worker

    @_worker.onmessage = (e) =>
      type = e.data.type
      eventName = 'on' + type.substr(0, 1).toUpperCase() + type.substr(1)
      @[eventName]?.call(this, e.data)

  postMessage: (type, data) ->
    @_worker.postMessage assign({ type }, data)
