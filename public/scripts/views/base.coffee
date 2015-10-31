module.exports =
class BaseView
  constructor: (layout) ->
    @_layout = layout

  controller: -> this
  view: (ctrl) -> @_layout @content(ctrl)

  content: ->
