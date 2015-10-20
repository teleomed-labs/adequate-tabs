Tabs = require('./tabs.coffee')
#require('lib/addPrefixedClass');
tabbed_views = []

### keyboard helper method for demo presentation ###

### enables left/right arrow keys to step through slides ###

handleKeyPress = (e) ->
  tabbed_view = _.last(tabbed_views)
  if !tabbed_view
    return
  current_tab = tabbed_view.tabs.model.get('current_tab_id')
  switch e.which
    when 37
      first_tab = tabbed_view.tabs.collection.first().get('id')
      if first_tab == current_tab
        if tabbed_views.length > 1
          tabbed_views.pop()
          handleKeyPress e
      else
        tabbed_view.triggerMethod 'previous'
    when 39
      last_tab = tabbed_view.tabs.collection.last().get('id')
      if last_tab == current_tab
        if tabbed_views.length > 1
          tabbed_views.pop()
          handleKeyPress e
      else
        tabbed_view.triggerMethod 'next'
    # console.log(e.which);
  return

$(window).on 'keyup', handleKeyPress

### helper view class for demo presentation ###

TabbedView = Marionette.LayoutView.extend(
  className: 'tabbed'
  template: _.template('<div class="tab-nav"></div><div class="tab-content"></div>')
  regions:
    nav: '.tab-nav'
    content: '.tab-content'
  initialize: ->
    tabbed_views.push this
    @listenTo @tabs.model, 'change:current_tab_id', @onChangeTab
    return
  onBeforeDestroy: ->
    tabbed_views = _.filter(tabbed_views, ((view) ->
      view.cid != @cid
    ), this)
    return
  onChangeTab: (model, tab) ->
    #$('body').addPrefixedClass('current-tab', tab);
    return
  behaviors: ->
    tab_options = _.extend({
      behaviorClass: Tabs
      region: @content
      tabs: []
      nav: region: @nav
    }, _.result(this, 'tabOptions'))
    { Tabs: tab_options }
)
module.exports = TabbedView
