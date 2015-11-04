Router = require('./router.coffee')

###
NOTE: don't look too closely at this code :) I plan to publish this behavior in
its own repo, but I have a bit of refactoring to do before I release it.
###

controller = undefined
class Controller extends Marionette.Controller
  initialize: ->
    #console.log('controller initialize');
    @cid = _.uniqueId('controller')
    @scope_model = new (Backbone.Model)
    return
  setCurrentTabIdForScope: (scope, tab_id) ->
    if !scope
      return
    if !tab_id
      throw new Error 'tab_id required'
    @scope_model.set scope, tab_id
    return
  getCurrentTabIdForScope: (scope) ->
    @scope_model.get(scope) or ''

class Tab extends Backbone.Model
  defaults:
    destroy: true
    label: ''
    viewOptions: {}
    visible: true
  initialize: ->
    # inherit superclass initialize
    Backbone.Model::initialize.apply this, arguments
    # if view attribute is not a generator, set destroy to false
    # so view can be re-used. not advisable for most use cases.
    #this.set('destroy', _.isFunction(this.get('view')));
    #log(this.get('id'), this.get('destroy'));
    @on 'invalid', ->
      console.error @get('id'), @validationError
      return
    return
  getView: ->
    View = @get('view')
    options = @get('viewOptions')
    if _.isFunction options then options = options()
    console.log 'view options are:'
    console.log options
    view = new View(options)
    view.$el.addClass 'tab tab-' + @get('id')
    view
  validate: (attrs) ->
    if !attrs.id
      return 'Tab requires an id.'
    if !attrs.view
      return 'Tab requires a view.'
    if !(attrs.view.prototype instanceof Backbone.View)
      return 'Tab view must be a Backbone.View'
    #if !_.isObject(attrs.viewOptions)
    #  return 'Tab viewOptions must be an object'
    if _.isUndefined(attrs.label)
      return 'Tab requires a label.'
    return

TabList = Backbone.Collection.extend(model: Tab)

class ButtonBarItemView extends Marionette.ItemView
  tagName: 'li'
  className: 'Tab'
  template: _.template '<%= label %>'
  triggers:
    'click': 'item:click'

class ButtonBarView extends Marionette.CollectionView
  tagName: 'ul'
  className: 'Tabs'
  childView: ButtonBarItemView
  initialize: (options) ->
    if !options.tabs
      throw new Error('Tabnav requires tabs.')
    @tabs = options.tabs
    @listenTo @tabs.model, 'change:current_tab_id', @setActiveItem
    @listenTo this, 'render', @setActiveItem
    # experimental support for tab.visible property
    @listenTo @collection, 'change:visible', @onChangeTabVisible
    window.foobuttons = this
    # DNR
    return
  onEvent: ->
    #console.log(arguments);
    return
  childEvents: 'item:click': 'onClickItem'
  onClickItem: (child) ->
    @tabs.setCurrentTabId child.model.get('id')
    return
  setActiveItem: ->
    #console.log(this.tabs.options.scope, 'setActiveItem');
    @$('.active').removeClass 'active'
    tab = @tabs.getCurrentTab()
    if tab
      view = @children.findByModel(tab)
      view.$el.addClass 'active'
    return
  showCollection: ->
    # override parent method to ignore tabs with visible:false
    ChildView = undefined
    visible_children = @collection.where(visible: true)
    _(visible_children).each ((child, index) ->
      ChildView = @getChildView(child)
      @addChild child, ChildView, index
      return
    ), this
    return
  onChangeTabVisible: (tab, visible, options) ->
    if visible
      # some hidden tab is now visible
      # re-render rather than try to figure out where to insert it
      @render()
    else
      # remove the view for this tab
      # and show the previous adjacent tab, or the first tab
      previous_tab_index = @collection.indexOf(tab) - 1 or 0
      view = @children.findByModel(tab)
      view.remove()
      @tabs.showTabByIndex previous_tab_index
    return

class MenuItemView extends Marionette.ItemView
  tagName: 'option'
  template: _.template('<%= label %>')
  initialize: ->
    @$el.attr 'value', @model.cid
    return

class MenuView extends Marionette.CollectionView
  tagName: 'select'
  className: 'tabmenu'
  childView: MenuItemView
  initialize: (options) ->
    if !options.tabs
      throw new Error('Tabnav requires tabs.')
    @tabs = options.tabs
    @collection = options.tabs.collection
    @listenTo @tabs.model, 'change:current_tab_id', @setActiveItem
    @listenTo this, 'render', @setActiveItem
    return
  events: 'change': 'onSelectItem'
  onRender: ->
    @$el.prepend '<option disabled>Select one:</option>'
    return
  onSelectItem: ->
    cid = @$el.val()
    tab = @collection.get(cid)
    @tabs.setCurrentTabId tab.get('id')
    return
  setActiveItem: ->
    tab = @tabs.getCurrentTab()
    if tab and tab.cid
      @$el.val tab.cid
    return

class Tabs extends Marionette.Behavior
  initialize: ->
    @options = @options or {}
    demodelay = localStorage.getItem('demodelay') or 0
    # DNR
    # validate options
    _.defaults @options,
      tabs: []
      routing: true
      show_initial_tab: true
      initial_tab_id: ''
      wraparound: false
    if !@options.region
      throw new Error('Tabs behavior requires a region')
    if demodelay
      @options.show_initial_tab = false
    # DNR
    @cid = _.uniqueId('tabs')
    #console.log('tabs init', this.options.scope, this.cid);
    @view.tabs = this
    # set up central controller
    if !controller
      controller = new Controller
    # if this.options.initial_tab_id isn't set explicitly,
    # use the last tab shown for this scope, if defined by a previous tab instance
    if !@options.initial_tab_id
      initial_tab_id = controller.getCurrentTabIdForScope(@options.scope)
      if initial_tab_id
        @options.initial_tab_id = initial_tab_id
    # this.initializeRouter();
    _.bindAll this, 'initializeRouter'
    # DNR - for demo
    _.delay @initializeRouter, demodelay
    # DNR - for demo
    # set up view model and tablist
    @model = new (Backbone.Model)(current_tab_id: @options.initial_tab_id)
    @collection = new TabList
    _.bindAll this, 'autoShowFirstTab'
    @autoShowFirstTab = _.debounce(@autoShowFirstTab, 20)
    window.footabs = this
    # DNR
    return
  initializeRouter: ->
    if @options.routing
      @router = new Router(
        controller: this
        scope: @options.scope
        appRoutes: '(:tab_id)(/)(*params)': 'routeTabId')
    return
  onShow: ->
    #console.log('tabs show');
    # set up model events
    @listenTo @model, 'change:current_tab_id', @onChangeCurrentTabId
    @on 'next', @showNextTab
    @on 'previous', @showPreviousTab
    @addTabs @options.tabs
    if @options.nav
      @createNav()
    _.defer @autoShowFirstTab
    return
  onDestroy: ->
    #console.log('tabs destroy');
    if @router
      @router.destroy()
    return
  onChangeCurrentTabId: (model, tab_id, options) ->
    #console.log('onChangeCurrentTabId', arguments);
    @showCurrentTab options
    controller.setCurrentTabIdForScope @options.scope, @model.get('current_tab_id')
    return
  addTab: (tab) ->
    if !(tab instanceof Tab)
      tab = new Tab(tab)
    if !tab.isValid()
      return tab.validationError
    @collection.add tab
    return
  addTabs: (tabs) ->
    _.each tabs, ((tab) ->
      @addTab tab
      return
    ), this
    return
  getTabById: (tab_id) ->
    @collection.findWhere id: tab_id
  getCurrentTab: ->
    tab_id = @model.get('current_tab_id')
    @getTabById tab_id
  showCurrentTab: (options) ->
    #console.log('showCurrentTab', this.options.scope, options);
    options = options or {}
    tab = @getCurrentTab()
    if tab and tab.isValid()
      if tab.get('shown')
        return
      #console.log('tab already showing');
      last_tab_id = @model.get('last_tab_id')
      last_tab = @getTabById(last_tab_id)
      if last_tab
        options.preventDestroy = !last_tab.get('destroy')
      tab_view = tab.getView()
      @view.triggerMethod 'before:show:tab', tab_view
      @options.region.show tab_view, options
      tab.set 'shown', true
      @listenTo tab_view, 'destroy', ->
        tab.unset 'shown'
        return
      @view.triggerMethod 'show:tab', tab_view
      @setHistory options
    return
  routeTabId: (tab_id) ->
    @setCurrentTabId tab_id
    return
  setCurrentTabId: (tab_id, options) ->
    options = options or {}
    tab = @getTabById(tab_id)
    if tab and tab.isValid()
      last_tab_id = @model.get('current_tab_id')
      @model.set 'last_tab_id', last_tab_id, options
      @model.set 'current_tab_id', tab_id, options
    return
  showTabById: (tab_id, options) ->
    @setCurrentTabId tab_id, options
    return
  showTabByIndex: (n) ->
    if @options.wraparound
      if n < 0
        n = @collection.length - 1
      if n > @collection.length - 1
        n = 0
    else
      n = Math.max(0, n)
      n = Math.min(n, @collection.length - 1)
    tab = @collection.at(n)
    @setCurrentTabId tab.get('id')
    return
  showNextTab: ->
    tab = @getCurrentTab()
    index = @collection.indexOf(tab)
    index++
    @showTabByIndex index
    return
  showPreviousTab: ->
    tab = @getCurrentTab()
    index = @collection.indexOf(tab)
    index--
    @showTabByIndex index
    return
  autoShowFirstTab: ->
    if @options.show_initial_tab
      first_tab = @collection.first()
      if first_tab
        @setCurrentTabId first_tab.get('id'), replace: true
        @showCurrentTab()
    return
  createNav: ->
    _.defaults @options.nav,
      view: ButtonBarView
      viewOptions: {}
    if !@options.nav.region
      throw new Error('Tab nav requires a region')
    navViewOptions = _.extend(@options.nav.viewOptions,
      tabs: this
      collection: @collection)
    @nav = new (@options.nav.view)(navViewOptions)
    @options.nav.region.show @nav
    return
  setHistory: (options) ->
    if !@router
      return
    tab_id = @model.get('current_tab_id')
    @router.navigate tab_id, options
    return

# define publicly accessible entities
Tabs.ButtonBarView = ButtonBarView
Tabs.MenuView = MenuView
module.exports = Tabs
