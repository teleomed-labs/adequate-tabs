class Controller extends Marionette.Object
  initialize: ->
    @cid = _.uniqueId('controller')
    @scope_model = new (Backbone.Model)

  setCurrentTabIdForScope: (scope, tab_id) ->
    return if not scope
    if not tab_id
      throw new Error 'tab_id required'
    @scope_model.set scope, tab_id

  getCurrentTabIdForScope: (scope) ->
    @scope_model.get(scope) or ''

module.exports = Controller
