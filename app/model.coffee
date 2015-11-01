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

ensureLatestRevision = (revision, callback) ->
  if latestRevision == revision
    callback()
  else
    latestRevision = revision
    baseDb.update { key: 'revisions' }, { $set: { latest: revision } }, upsert: true, callback

exports.getCheckers = (revision, callback) ->
  ensureCache(revision)

  checkerNames = Object.keys(checkers)
  checkerCounts = {}

  remaining = checkerNames.length
  countCallback = (checker, err, count) ->
    checkerCounts[checker] = count
    remaining -= 1
    if remaining == 0
      callback(checkerCounts)

  for checker in checkerNames
    cache.db.count { checker }, countCallback.bind(null, checker)

exports.hasData = (revision, callback) ->
  fs.exists filenameForRevision(revision), callback

exports.findData = (revision, checker, callback) ->
  ensureCache revision
  cache.db.find { checker }, (err, docs) ->
    perFileData = {}
    for doc in docs
      perFileData[doc.file] ?= []
      perFileData[doc.file].push doc
    callback(perFileData)

exports.findLatestRevision = (callback) ->
  if latestRevision
    callback latestRevision
  else
    baseDb.findOne { key: 'revisions' }, (err, doc) -> callback doc?.latest

exports.save = (revision, data, callback) ->
  ensureCache revision
  cache.db.insert data, ensureLatestRevision.bind(null, revision, callback)

exports.DATAROOT = DATAROOT
