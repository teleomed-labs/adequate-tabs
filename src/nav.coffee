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

  childEvents: 'item:click': 'onClickItem'

  onClickItem: (child) ->
    @tabs.setCurrentTabId child.model.get('id')

  setActiveItem: ->
    @$('.active').removeClass 'active'
    tab = @tabs.getCurrentTab()
    if tab
      view = @children.findByModel(tab)
      view.$el.addClass 'active'

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

class MenuItemView extends Marionette.ItemView
  tagName: 'option'
  template: _.template('<%= label %>')
  initialize: ->
    @$el.attr 'value', @model.cid

class MenuView extends Marionette.CollectionView
  tagName: 'select'
  className: 'tabmenu'
  childView: MenuItemView

  initialize: (options) ->
    if not options.tabs
      throw new Error('Tabnav requires tabs.')
    @tabs = options.tabs
    @collection = options.tabs.collection
    @listenTo @tabs.model, 'change:current_tab_id', @setActiveItem
    @listenTo this, 'render', @setActiveItem

  events:
    'change': 'onSelectItem'

  onRender: ->
    @$el.prepend '<option disabled>Select one:</option>'

  onSelectItem: ->
    cid = @$el.val()
    tab = @collection.get(cid)
    @tabs.setCurrentTabId tab.get('id')

  setActiveItem: ->
    tab = @tabs.getCurrentTab()
    if tab and tab.cid
      @$el.val tab.cid

module.exports =
  ButtonBarView: ButtonBarView
  MenuView: MenuView
