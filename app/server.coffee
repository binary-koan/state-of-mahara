express = require 'express'
Checker = require './checker'

app = express()
server = require('http').Server(app)
io = require('socket.io')(server)

app.use express.static('public')

io.on 'connection', (socket) ->
  Checker.getLatestResults (data) ->
    console.log 'received data'
    console.log data
    if data.error
      socket.emit 'failed', data
    else if data.progress
      socket.emit 'progress', data
    else if data
      socket.emit 'data', data
    else
      socket.emit 'error', error: 'Unspecified error'

server.listen 3000
