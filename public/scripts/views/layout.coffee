m = require 'mithril'

module.exports =
mainLayout = (content) ->
  m '.container', m('.row', m('.twelve.columns', content))
