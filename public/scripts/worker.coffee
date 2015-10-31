Datastore = require 'nedb'
{ map } = require 'lodash'

AbstractWorker = require './util/worker'

class DataWorker extends AbstractWorker
  constructor: ->
    super self
    @_db = new Datastore()

  onDataLoaded: ({ data }) ->
    @_db.remove {}, multi: true, =>
      @_checkers = new Set(map(data, (item) -> item.checker))
      @_db.insert data, @postMessage.bind(this, 'databaseReady', checkers: @_checkers)

  onGetData: ({ checker }) ->
    @_db.find { checker }, (err, docs) =>
      @postMessage 'data', checker: checker, data: docs

new DataWorker()
