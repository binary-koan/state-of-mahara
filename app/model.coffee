fs = require 'fs'
path = require 'path'
Datastore = require 'nedb'

DATAROOT = path.resolve(process.env.OPENSHIFT_DATA_DIR || "#{__dirname}/../.data")
baseDb = new Datastore(filename: DATAROOT + '/db/data.db', autoload: true)

filenameForRevision = (revision) -> "#{DATAROOT}/db/#{revision}.db"

allFromFile = (revision, callback) ->
  db = new Datastore(filename: filenameForRevision(revision), autoload: true)
  db.find {}, (err, docs) -> callback docs

exports.findData = getLatestData = (revision, callback) ->
  filename = filenameForRevision(revision)
  fs.exists filename, (exists) ->
    if exists
      allFromFile revision, callback
    else
      callback null

exports.findLatestRevision = findLatestRevision = (callback) ->
  baseDb.findOne { key: 'revisions' }, (err, doc) -> callback doc?.latest

exports.save = (revision, data, callback) ->
  filename = filenameForRevision(revision)
  fs.unlinkSync(filename) if fs.existsSync(filename)

  db = new Datastore(filename: filename, autoload: true)
  db.insert data, ->
    baseDb.update { key: 'revisions' }, { $set: { latest: revision } }, upsert: true, callback

exports.DATAROOT = DATAROOT
