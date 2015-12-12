fs = require 'fs'
{ map } = require 'lodash'
path = require 'path'
Datastore = require 'nedb'

checkers = require './checker/index'

DATAROOT = path.resolve(process.env.OPENSHIFT_DATA_DIR || "#{__dirname}/../.data")
baseDb = new Datastore(filename: DATAROOT + '/db/data.db', autoload: true)

latestRevision = null
cache = { revision: null, db: null }

filenameForRevision = (revision) -> "#{DATAROOT}/db/#{revision}.db"

revisionDatabase = (revision) -> db = new Datastore(filename: filenameForRevision(revision), autoload: true)

ensureCache = (revision) ->
  unless cache.revision == revision
    cache = { revision: revision, db: revisionDatabase(revision) }

exports.hasData = (revision) ->
  fs.existsSync filenameForRevision(revision)

exports.findData = (revision, callback) ->
  ensureCache revision
  cache.db.find {}, (err, docs) ->
    perFileData = {}
    for doc in docs
      perFileData[doc.file] ?= []
      perFileData[doc.file].push doc
    callback(perFileData)

exports.save = (revision, data, callback) ->
  fs.unlink filenameForRevision(revision), ->
    ensureCache revision
    cache.db.insert data, callback

exports.DATAROOT = DATAROOT
