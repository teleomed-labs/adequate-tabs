Tabs = require('./tabs.coffee')
tabbed_views = []

class TabbedView extends Marionette.LayoutView
  className: 'tabbed'
  template: _.template '''
    <div class="tab-nav"></div><div class="tab-content"></div>
  '''

  regions:
    nav: '.tab-nav'
    content: '.tab-content'

  initialize: ->
    tabbed_views.push this
    @listenTo @tabs.model, 'change:current_tab_id', @onChangeTab

  onBeforeDestroy: ->
    tabbed_views = _.filter(tabbed_views, ((view) ->
      view.cid != @cid
    ), this)

  onChangeTab: (model, tab) ->
    # TODO: show current tab

  behaviors: ->
    tab_options = _.extend({
      behaviorClass: Tabs
      region: @content
      tabs: []
      nav: region: @nav
    }, _.result(this, 'tabOptions'))
    { Tabs: tab_options }

module.exports = TabbedView
