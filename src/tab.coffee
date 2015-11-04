class Tab extends Backbone.Model
  defaults:
    destroy: true
    label: ''
    viewOptions: {}
    visible: true

  initialize: ->
    @on 'invalid', -> console.error @get('id'), @validationError

  getView: ->
    View = @get('view')
    options = @get('viewOptions')
    if _.isFunction options then options = options()
    view = new View(options)
    view.$el.addClass 'tab tab-' + @get('id')
    view

  validate: (attrs) ->
    if not attrs.id
      return 'Tab requires an id.'
    if not attrs.view
      return 'Tab requires a view.'
    if not attrs.view.prototype instanceof Backbone.View
      return 'Tab view must be a Backbone.View'
    if _.isUndefined(attrs.label)
      return 'Tab requires a label.'

module.exports = Tab
