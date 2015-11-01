express = require 'express'
Checker = require './checker'
model = require './model'

app = express()
server = require('http').Server(app)
io = require('socket.io')(server)

app.use express.static('public')

io.on 'connection', (socket) ->
  currentRevision = null

  dataCallback = (data) ->
    if data.error
      socket.emit 'failed', data
    else if data.progress
      socket.emit 'progress', data
    else if data.complete
      currentRevision = data.revision
      socket.emit 'ready', data
    else
      console.log(data)
      socket.emit 'failed', error: 'Unspecified error'

  socket.on 'getLatest', ->
    Checker.run forceUpdate: false, callback: dataCallback

  socket.on 'forceUpdate', ->
    Checker.run forceUpdate: true, callback: dataCallback

  socket.on 'getCheckers', ->
    model.getCheckers currentRevision, (checkers) ->
      socket.emit 'checkers', { checkers }

  socket.on 'load', ({ checker }) ->
    model.findData currentRevision, checker, (data) ->
      socket.emit 'data', { checker, data }

server.listen 3000
