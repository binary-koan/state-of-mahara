fs = require 'fs'
{ map } = require 'lodash'
path = require 'path'
Datastore = require 'nedb'

DATAROOT = path.resolve(process.env.OPENSHIFT_DATA_DIR || "#{__dirname}/../.data")
baseDb = new Datastore(filename: DATAROOT + '/db/data.db', autoload: true)
cache = { revision: null, db: null, checkers: null }

filenameForRevision = (revision) -> "#{DATAROOT}/db/#{revision}.db"

revisionDatabase = (revision) -> db = new Datastore(filename: filenameForRevision(revision), autoload: true)

findInFile = (revision, checker, callback) ->
  db = revisionDatabase(revision)
  cache = { revision, db }
  findCheckerData db, checker, callback

findCheckerData = (db, checker, callback) ->
  db.find { checker }, (err, docs) -> callback docs

exports.getCheckers = (revision, callback) ->
  db = null

  if cache.revision == revision
    if cache.checkers
      callback cache.checkers
      return
    else
      db = cache.db
  else
    db = revisionDatabase(revision)

  db.find {}, (err, docs) ->
    checkers = new Set(map(docs, (doc) -> doc.checker))
    checkersWithCount = {}

    remainingOperations = checkers.size
    countCallback = (checker, err, count) ->
      checkersWithCount[checker] = count
      remainingOperations -= 1
      if remainingOperations == 0
        callback(checkersWithCount)

    checkers.forEach (checker) ->
      db.count { checker }, countCallback.bind(null, checker)

exports.findData = (revision, checker, callback) ->
  if cache.revision == revision
    findCheckerData cache.db, checker, callback
    return

  filename = filenameForRevision(revision)
  fs.exists filename, (exists) ->
    if exists
      findInFile revision, checker, callback
    else
      callback null

exports.findLatestRevision = (callback) ->
  baseDb.findOne { key: 'revisions' }, (err, doc) -> callback doc?.latest

exports.save = (revision, data, callback) ->
  filename = filenameForRevision(revision)
  fs.unlinkSync(filename) if fs.existsSync(filename)

  db = new Datastore(filename: filename, autoload: true)
  db.insert data, ->
    cache = { revision, db }
    baseDb.update { key: 'revisions' }, { $set: { latest: revision } }, upsert: true, callback

exports.DATAROOT = DATAROOT
