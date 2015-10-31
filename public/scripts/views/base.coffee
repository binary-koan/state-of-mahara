module.exports =
class BaseView
  constructor: (layout) ->
    @_layout = layout

  controller: ->
  view: -> @_layout @content()

  content: ->
