(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var TabbedView, root;

TabbedView = require('./tabbed.coffee');

root = typeof exports !== "undefined" && exports !== null ? exports : window;

root.AdequateTabs = {
  TabbedView: TabbedView
};


},{"./tabbed.coffee":3}],2:[function(require,module,exports){
var Router,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Backbone.History.prototype.route = function(route, callback, router) {
  this.handlers.unshift({
    router: router,
    route: route,
    callback: callback
  });
};

Router = (function(superClass) {
  extend(Router, superClass);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.initialize = function(options) {
    Marionette.AppRouter.prototype.initialize.apply(this, arguments);
    _.bindAll(this, 'checkState');
    _.defer(this.checkState);
  };

  Router.prototype.checkState = function() {
    if (Backbone.History.started) {
      Backbone.history.loadUrl();
    } else {
      if (!Backbone.history) {
        Backbone.history = new Backbone.History;
      }
      Backbone.history.start({
        pushState: true
      });
    }
  };

  Router.prototype.route = function(route, name, callback) {
    var router;
    if (!_.isRegExp(route)) {
      route = this._routeToRegExp(route);
    }
    if (_.isFunction(name)) {
      callback = name;
      name = '';
    }
    if (!callback) {
      callback = this[name];
    }
    router = this;
    Backbone.history.route(route, (function(fragment) {
      var args;
      args = router._extractParameters(route, fragment);
      router.execute(callback, args);
      router.trigger.apply(router, ['route:' + name].concat(args));
      router.trigger('route', name, args);
      Backbone.history.trigger('route', router, name, args);
    }), this);
    return this;
  };

  Router.prototype._addAppRoute = function(controller, route, methodName) {
    if (this.options.scope) {
      route = this.options.scope + '/' + route;
    }
    Marionette.AppRouter.prototype._addAppRoute.apply(this, [controller, route, methodName]);
  };

  Router.prototype.navigate = function(fragment, options) {

    /* jshint maxcomplexity: 11 */
    var current_fragment, defaults, re, scope;
    options = options || {};
    current_fragment = Backbone.history.fragment;
    scope = _.isFunction(this.options.scope) ? this.options.scope() : this.options.scope;
    defaults = {};
    re = void 0;

    /* jshint maxdepth: 4 */
    if (scope) {
      if (fragment) {
        fragment = scope + '/' + fragment;
        re = new RegExp(scope + '/?$', 'i');
        if (current_fragment.match(re)) {
          defaults.replace = true;
        }
      } else {
        fragment = scope;
      }
      re = new RegExp(scope, 'i');
      if (!current_fragment.match(re)) {
        if (!options.force) {
          console.error('Tab URL is out of scope.', scope, current_fragment);
          return this;
        }
      }
    }
    re = new RegExp(fragment);
    if (current_fragment.match(re)) {
      if (!options.force) {
        return this;
      }
    }
    re = new RegExp(fragment + '/?$', 'i');
    if (current_fragment.match(re)) {
      defaults.replace = true;
    }
    _.defaults(options, defaults);
    return Marionette.AppRouter.prototype.navigate.apply(this, [fragment, options]);
  };

  Router.prototype.destroy = function() {
    Backbone.history.handlers = _.filter(Backbone.history.handlers, (function(handler) {
      return handler.router !== this;
    }), this);
  };

  return Router;

})(Marionette.AppRouter);

module.exports = Router;


},{}],3:[function(require,module,exports){
var TabbedView, Tabs, handleKeyPress, tabbed_views;

Tabs = require('./tabs.coffee');

tabbed_views = [];


/* keyboard helper method for demo presentation */


/* enables left/right arrow keys to step through slides */

handleKeyPress = function(e) {
  var current_tab, first_tab, last_tab, tabbed_view;
  tabbed_view = _.last(tabbed_views);
  if (!tabbed_view) {
    return;
  }
  current_tab = tabbed_view.tabs.model.get('current_tab_id');
  switch (e.which) {
    case 37:
      first_tab = tabbed_view.tabs.collection.first().get('id');
      if (first_tab === current_tab) {
        if (tabbed_views.length > 1) {
          tabbed_views.pop();
          handleKeyPress(e);
        }
      } else {
        tabbed_view.triggerMethod('previous');
      }
      break;
    case 39:
      last_tab = tabbed_view.tabs.collection.last().get('id');
      if (last_tab === current_tab) {
        if (tabbed_views.length > 1) {
          tabbed_views.pop();
          handleKeyPress(e);
        }
      } else {
        tabbed_view.triggerMethod('next');
      }
  }
};

$(window).on('keyup', handleKeyPress);


/* helper view class for demo presentation */

TabbedView = Marionette.LayoutView.extend({
  className: 'tabbed',
  template: _.template('<div class="tab-nav"></div><div class="tab-content"></div>'),
  regions: {
    nav: '.tab-nav',
    content: '.tab-content'
  },
  initialize: function() {
    tabbed_views.push(this);
    this.listenTo(this.tabs.model, 'change:current_tab_id', this.onChangeTab);
  },
  onBeforeDestroy: function() {
    tabbed_views = _.filter(tabbed_views, (function(view) {
      return view.cid !== this.cid;
    }), this);
  },
  onChangeTab: function(model, tab) {},
  behaviors: function() {
    var tab_options;
    tab_options = _.extend({
      behaviorClass: Tabs,
      region: this.content,
      tabs: [],
      nav: {
        region: this.nav
      }
    }, _.result(this, 'tabOptions'));
    return {
      Tabs: tab_options
    };
  }
});

module.exports = TabbedView;


},{"./tabs.coffee":4}],4:[function(require,module,exports){
var ButtonBarItemView, ButtonBarView, Controller, MenuItemView, MenuView, Router, Tab, TabList, Tabs, controller,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Router = require('./router.coffee');


/*
NOTE: don't look too closely at this code :) I plan to publish this behavior in
its own repo, but I have a bit of refactoring to do before I release it.
 */

controller = void 0;

Controller = (function(superClass) {
  extend(Controller, superClass);

  function Controller() {
    return Controller.__super__.constructor.apply(this, arguments);
  }

  Controller.prototype.initialize = function() {
    this.cid = _.uniqueId('controller');
    this.scope_model = new Backbone.Model;
  };

  Controller.prototype.setCurrentTabIdForScope = function(scope, tab_id) {
    if (!scope) {
      return;
    }
    if (!tab_id) {
      throw new Error('tab_id required');
    }
    this.scope_model.set(scope, tab_id);
  };

  Controller.prototype.getCurrentTabIdForScope = function(scope) {
    return this.scope_model.get(scope) || '';
  };

  return Controller;

})(Marionette.Controller);

Tab = (function(superClass) {
  extend(Tab, superClass);

  function Tab() {
    return Tab.__super__.constructor.apply(this, arguments);
  }

  Tab.prototype.defaults = {
    destroy: true,
    label: '',
    viewOptions: {},
    visible: true
  };

  Tab.prototype.initialize = function() {
    Backbone.Model.prototype.initialize.apply(this, arguments);
    this.on('invalid', function() {
      console.error(this.get('id'), this.validationError);
    });
  };

  Tab.prototype.getView = function() {
    var View, options, view;
    View = this.get('view');
    options = this.get('viewOptions');
    if (_.isFunction(options)) {
      options = options();
    }
    console.log('view options are:');
    console.log(options);
    view = new View(options);
    view.$el.addClass('tab tab-' + this.get('id'));
    return view;
  };

  Tab.prototype.validate = function(attrs) {
    if (!attrs.id) {
      return 'Tab requires an id.';
    }
    if (!attrs.view) {
      return 'Tab requires a view.';
    }
    if (!(attrs.view.prototype instanceof Backbone.View)) {
      return 'Tab view must be a Backbone.View';
    }
    if (_.isUndefined(attrs.label)) {
      return 'Tab requires a label.';
    }
  };

  return Tab;

})(Backbone.Model);

TabList = Backbone.Collection.extend({
  model: Tab
});

ButtonBarItemView = (function(superClass) {
  extend(ButtonBarItemView, superClass);

  function ButtonBarItemView() {
    return ButtonBarItemView.__super__.constructor.apply(this, arguments);
  }

  ButtonBarItemView.prototype.tagName = 'li';

  ButtonBarItemView.prototype.className = 'Tab';

  ButtonBarItemView.prototype.template = _.template('<%= label %>');

  ButtonBarItemView.prototype.triggers = {
    'click': 'item:click'
  };

  return ButtonBarItemView;

})(Marionette.ItemView);

ButtonBarView = (function(superClass) {
  extend(ButtonBarView, superClass);

  function ButtonBarView() {
    return ButtonBarView.__super__.constructor.apply(this, arguments);
  }

  ButtonBarView.prototype.tagName = 'ul';

  ButtonBarView.prototype.className = 'Tabs';

  ButtonBarView.prototype.childView = ButtonBarItemView;

  ButtonBarView.prototype.initialize = function(options) {
    if (!options.tabs) {
      throw new Error('Tabnav requires tabs.');
    }
    this.tabs = options.tabs;
    this.listenTo(this.tabs.model, 'change:current_tab_id', this.setActiveItem);
    this.listenTo(this, 'render', this.setActiveItem);
    this.listenTo(this.collection, 'change:visible', this.onChangeTabVisible);
    window.foobuttons = this;
  };

  ButtonBarView.prototype.onEvent = function() {};

  ButtonBarView.prototype.childEvents = {
    'item:click': 'onClickItem'
  };

  ButtonBarView.prototype.onClickItem = function(child) {
    this.tabs.setCurrentTabId(child.model.get('id'));
  };

  ButtonBarView.prototype.setActiveItem = function() {
    var tab, view;
    this.$('.active').removeClass('active');
    tab = this.tabs.getCurrentTab();
    if (tab) {
      view = this.children.findByModel(tab);
      view.$el.addClass('active');
    }
  };

  ButtonBarView.prototype.showCollection = function() {
    var ChildView, visible_children;
    ChildView = void 0;
    visible_children = this.collection.where({
      visible: true
    });
    _(visible_children).each((function(child, index) {
      ChildView = this.getChildView(child);
      this.addChild(child, ChildView, index);
    }), this);
  };

  ButtonBarView.prototype.onChangeTabVisible = function(tab, visible, options) {
    var previous_tab_index, view;
    if (visible) {
      this.render();
    } else {
      previous_tab_index = this.collection.indexOf(tab) - 1 || 0;
      view = this.children.findByModel(tab);
      view.remove();
      this.tabs.showTabByIndex(previous_tab_index);
    }
  };

  return ButtonBarView;

})(Marionette.CollectionView);

MenuItemView = (function(superClass) {
  extend(MenuItemView, superClass);

  function MenuItemView() {
    return MenuItemView.__super__.constructor.apply(this, arguments);
  }

  MenuItemView.prototype.tagName = 'option';

  MenuItemView.prototype.template = _.template('<%= label %>');

  MenuItemView.prototype.initialize = function() {
    this.$el.attr('value', this.model.cid);
  };

  return MenuItemView;

})(Marionette.ItemView);

MenuView = (function(superClass) {
  extend(MenuView, superClass);

  function MenuView() {
    return MenuView.__super__.constructor.apply(this, arguments);
  }

  MenuView.prototype.tagName = 'select';

  MenuView.prototype.className = 'tabmenu';

  MenuView.prototype.childView = MenuItemView;

  MenuView.prototype.initialize = function(options) {
    if (!options.tabs) {
      throw new Error('Tabnav requires tabs.');
    }
    this.tabs = options.tabs;
    this.collection = options.tabs.collection;
    this.listenTo(this.tabs.model, 'change:current_tab_id', this.setActiveItem);
    this.listenTo(this, 'render', this.setActiveItem);
  };

  MenuView.prototype.events = {
    'change': 'onSelectItem'
  };

  MenuView.prototype.onRender = function() {
    this.$el.prepend('<option disabled>Select one:</option>');
  };

  MenuView.prototype.onSelectItem = function() {
    var cid, tab;
    cid = this.$el.val();
    tab = this.collection.get(cid);
    this.tabs.setCurrentTabId(tab.get('id'));
  };

  MenuView.prototype.setActiveItem = function() {
    var tab;
    tab = this.tabs.getCurrentTab();
    if (tab && tab.cid) {
      this.$el.val(tab.cid);
    }
  };

  return MenuView;

})(Marionette.CollectionView);

Tabs = (function(superClass) {
  extend(Tabs, superClass);

  function Tabs() {
    return Tabs.__super__.constructor.apply(this, arguments);
  }

  Tabs.prototype.initialize = function() {
    var demodelay, initial_tab_id;
    this.options = this.options || {};
    demodelay = localStorage.getItem('demodelay') || 0;
    _.defaults(this.options, {
      tabs: [],
      routing: true,
      show_initial_tab: true,
      initial_tab_id: '',
      wraparound: false
    });
    if (!this.options.region) {
      throw new Error('Tabs behavior requires a region');
    }
    if (demodelay) {
      this.options.show_initial_tab = false;
    }
    this.cid = _.uniqueId('tabs');
    this.view.tabs = this;
    if (!controller) {
      controller = new Controller;
    }
    if (!this.options.initial_tab_id) {
      initial_tab_id = controller.getCurrentTabIdForScope(this.options.scope);
      if (initial_tab_id) {
        this.options.initial_tab_id = initial_tab_id;
      }
    }
    _.bindAll(this, 'initializeRouter');
    _.delay(this.initializeRouter, demodelay);
    this.model = new Backbone.Model({
      current_tab_id: this.options.initial_tab_id
    });
    this.collection = new TabList;
    _.bindAll(this, 'autoShowFirstTab');
    this.autoShowFirstTab = _.debounce(this.autoShowFirstTab, 20);
    window.footabs = this;
  };

  Tabs.prototype.initializeRouter = function() {
    if (this.options.routing) {
      this.router = new Router({
        controller: this,
        scope: this.options.scope,
        appRoutes: {
          '(:tab_id)(/)(*params)': 'routeTabId'
        }
      });
    }
  };

  Tabs.prototype.onShow = function() {
    this.listenTo(this.model, 'change:current_tab_id', this.onChangeCurrentTabId);
    this.on('next', this.showNextTab);
    this.on('previous', this.showPreviousTab);
    this.addTabs(this.options.tabs);
    if (this.options.nav) {
      this.createNav();
    }
    _.defer(this.autoShowFirstTab);
  };

  Tabs.prototype.onDestroy = function() {
    if (this.router) {
      this.router.destroy();
    }
  };

  Tabs.prototype.onChangeCurrentTabId = function(model, tab_id, options) {
    this.showCurrentTab(options);
    controller.setCurrentTabIdForScope(this.options.scope, this.model.get('current_tab_id'));
  };

  Tabs.prototype.addTab = function(tab) {
    if (!(tab instanceof Tab)) {
      tab = new Tab(tab);
    }
    if (!tab.isValid()) {
      return tab.validationError;
    }
    this.collection.add(tab);
  };

  Tabs.prototype.addTabs = function(tabs) {
    _.each(tabs, (function(tab) {
      this.addTab(tab);
    }), this);
  };

  Tabs.prototype.getTabById = function(tab_id) {
    return this.collection.findWhere({
      id: tab_id
    });
  };

  Tabs.prototype.getCurrentTab = function() {
    var tab_id;
    tab_id = this.model.get('current_tab_id');
    return this.getTabById(tab_id);
  };

  Tabs.prototype.showCurrentTab = function(options) {
    var last_tab, last_tab_id, tab, tab_view;
    options = options || {};
    tab = this.getCurrentTab();
    if (tab && tab.isValid()) {
      if (tab.get('shown')) {
        return;
      }
      last_tab_id = this.model.get('last_tab_id');
      last_tab = this.getTabById(last_tab_id);
      if (last_tab) {
        options.preventDestroy = !last_tab.get('destroy');
      }
      tab_view = tab.getView();
      this.view.triggerMethod('before:show:tab', tab_view);
      this.options.region.show(tab_view, options);
      tab.set('shown', true);
      this.listenTo(tab_view, 'destroy', function() {
        tab.unset('shown');
      });
      this.view.triggerMethod('show:tab', tab_view);
      this.setHistory(options);
    }
  };

  Tabs.prototype.routeTabId = function(tab_id) {
    this.setCurrentTabId(tab_id);
  };

  Tabs.prototype.setCurrentTabId = function(tab_id, options) {
    var last_tab_id, tab;
    options = options || {};
    tab = this.getTabById(tab_id);
    if (tab && tab.isValid()) {
      last_tab_id = this.model.get('current_tab_id');
      this.model.set('last_tab_id', last_tab_id, options);
      this.model.set('current_tab_id', tab_id, options);
    }
  };

  Tabs.prototype.showTabById = function(tab_id, options) {
    this.setCurrentTabId(tab_id, options);
  };

  Tabs.prototype.showTabByIndex = function(n) {
    var tab;
    if (this.options.wraparound) {
      if (n < 0) {
        n = this.collection.length - 1;
      }
      if (n > this.collection.length - 1) {
        n = 0;
      }
    } else {
      n = Math.max(0, n);
      n = Math.min(n, this.collection.length - 1);
    }
    tab = this.collection.at(n);
    this.setCurrentTabId(tab.get('id'));
  };

  Tabs.prototype.showNextTab = function() {
    var index, tab;
    tab = this.getCurrentTab();
    index = this.collection.indexOf(tab);
    index++;
    this.showTabByIndex(index);
  };

  Tabs.prototype.showPreviousTab = function() {
    var index, tab;
    tab = this.getCurrentTab();
    index = this.collection.indexOf(tab);
    index--;
    this.showTabByIndex(index);
  };

  Tabs.prototype.autoShowFirstTab = function() {
    var first_tab;
    if (this.options.show_initial_tab) {
      if (this.model.get('current_tab_id')) {
        this.showCurrentTab();
      } else {
        first_tab = this.collection.first();
        if (first_tab) {
          this.setCurrentTabId(first_tab.get('id'), {
            replace: true
          });
        }
      }
    }
  };

  Tabs.prototype.createNav = function() {
    var navViewOptions;
    _.defaults(this.options.nav, {
      view: ButtonBarView,
      viewOptions: {}
    });
    if (!this.options.nav.region) {
      throw new Error('Tab nav requires a region');
    }
    navViewOptions = _.extend(this.options.nav.viewOptions, {
      tabs: this,
      collection: this.collection
    });
    this.nav = new this.options.nav.view(navViewOptions);
    this.options.nav.region.show(this.nav);
  };

  Tabs.prototype.setHistory = function(options) {
    var tab_id;
    if (!this.router) {
      return;
    }
    tab_id = this.model.get('current_tab_id');
    this.router.navigate(tab_id, options);
  };

  return Tabs;

})(Marionette.Behavior);

Tabs.ButtonBarView = ButtonBarView;

Tabs.MenuView = MenuView;

module.exports = Tabs;


},{"./router.coffee":2}]},{},[1]);
