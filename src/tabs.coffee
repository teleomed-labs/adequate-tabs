Router = require('./router.coffee')
Controller = require('./scoped_controller.coffee')
Tab = require('./tab.coffee')
{ ButtonBarView, MenuView } = require('./nav.coffee')

TabList = Backbone.Collection.extend(model: Tab)

controller = undefined

class Tabs extends Marionette.Behavior
  initialize: ->
    @options = @options or {}

    _.defaults @options,
      tabs: []
      routing: true
      show_initial_tab: true
      initial_tab_id: ''
      wraparound: false

    if not @options.region
      throw new Error('Tabs behavior requires a region')

    @cid = _.uniqueId('tabs')
    @view.tabs = this

    # set up central controller
    controller = new Controller if not controller

    # if this.options.initial_tab_id isn't set explicitly,
    # use the last tab shown for this scope, if defined by a previous tab instance
    if not @options.initial_tab_id
      initial_tab_id = controller.getCurrentTabIdForScope(@options.scope)
      if initial_tab_id
        @options.initial_tab_id = initial_tab_id

    # this.initializeRouter();
    _.bindAll this, 'initializeRouter'

    # set up view model and tablist
    @model = new Backbone.Model(current_tab_id: @options.initial_tab_id)
    @collection = new TabList
    _.bindAll this, 'autoShowFirstTab'
    @autoShowFirstTab = _.debounce(@autoShowFirstTab, 20)

  # TODO: this does not appear to be called
  initializeRouter: ->
    if @options.routing
      @router = new Router(
        controller: this
        scope: @options.scope
        appRoutes: '(:tab_id)(/)(*params)': 'routeTabId')

  onShow: ->
    # set up model events
    @listenTo @model, 'change:current_tab_id', @onChangeCurrentTabId
    @on 'next', @showNextTab
    @on 'previous', @showPreviousTab
    @addTabs @options.tabs
    if @options.nav
      @createNav()
    _.defer @autoShowFirstTab

  onDestroy: ->
    @router.destroy() if @router

  onChangeCurrentTabId: (model, tab_id, options) ->
    @showCurrentTab options
    controller.setCurrentTabIdForScope @options.scope, @model.get('current_tab_id')

  addTab: (tab) ->
    if not (tab instanceof Tab)
      tab = new Tab(tab)
    if not tab.isValid()
      return tab.validationError
    @collection.add tab

  addTabs: (tabs) ->
    _.each tabs, ((tab) ->
      @addTab tab
      return
    ), this

  getTabById: (tab_id) ->
    @collection.findWhere id: tab_id

  getCurrentTab: ->
    tab_id = @model.get('current_tab_id')
    @getTabById tab_id

  showCurrentTab: (options) ->
    options = options or {}

    tab = @getCurrentTab()

    if tab and tab.isValid()
      return if tab.get('shown')
      last_tab_id = @model.get('last_tab_id')
      last_tab = @getTabById(last_tab_id)
      if last_tab
        options.preventDestroy = !last_tab.get('destroy')
      tab_view = tab.getView()
      @view.triggerMethod 'before:show:tab', tab_view
      @options.region.show tab_view, options
      tab.set 'shown', true
      @listenTo tab_view, 'destroy', -> tab.unset 'shown'
      @view.triggerMethod 'show:tab', tab_view
      @setHistory options
    else
      @options.region.empty()
      @setHistory(options)

  routeTabId: (tab_id) ->
    @setCurrentTabId tab_id

  setCurrentTabId: (tab_id, options) ->
    options = options or {}
    tab = @getTabById(tab_id)
    if tab and tab.isValid()
      last_tab_id = @model.get('current_tab_id')
      @model.set 'last_tab_id', last_tab_id, options
      @model.set 'current_tab_id', tab_id, options

  showTabById: (tab_id, options) ->
    @setCurrentTabId tab_id, options

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

  showNextTab: ->
    tab = @getCurrentTab()
    index = @collection.indexOf(tab)
    index++
    @showTabByIndex index

  showPreviousTab: ->
    tab = @getCurrentTab()
    index = @collection.indexOf(tab)
    index--
    @showTabByIndex index

  autoShowFirstTab: ->
    if @options.show_initial_tab
      first_tab = @collection.first()
      if first_tab
        @setCurrentTabId first_tab.get('id'), replace: true
        @showCurrentTab()

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

  setHistory: (options) ->
    return if not @router

    tab_id = @model.get('current_tab_id')
    @router.navigate tab_id, options

# define publicly accessible entities
Tabs.ButtonBarView = ButtonBarView
Tabs.MenuView = MenuView
module.exports = Tabs
