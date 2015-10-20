# override Backbone.History.prototype.route
# to allow for handlers to have a router associated with them
# this allows us to remove routes dynamically e.g. in router.destroy (see below)

Backbone.History::route = (route, callback, router) ->
  @handlers.unshift
    router: router
    route: route
    callback: callback
  return

class Router extends Marionette.AppRouter
  initialize: (options) ->
    Marionette.AppRouter::initialize.apply this, arguments
    _.bindAll this, 'checkState'

    # initialize is called first in the Marionette.AppRouter constructor,
    # before appRoutes have been processed have to defer checkState so that
    # rest of constructor can complete first

    _.defer @checkState
    return
  checkState: ->
    if Backbone.History.started
      # if this router was initialized after history started,
      # it might have added a route that need to be triggered
      # this tells Backbone.history to check the current fragment for any matching routes
      Backbone.history.loadUrl()
      # TODO DNR need to do ^this in a way that *only* checks this router's routes
    else
      # console.log('Backbone.history not started yet');
      if !Backbone.history
        Backbone.history = new (Backbone.History)
      Backbone.history.start pushState: true
    return
  route: (route, name, callback) ->
    if !_.isRegExp(route)
      route = @_routeToRegExp(route)
    if _.isFunction(name)
      callback = name
      name = ''
    if !callback
      callback = @[name]
    router = this
    Backbone.history.route route, ((fragment) ->
      args = router._extractParameters(route, fragment)
      router.execute callback, args
      router.trigger.apply router, [ 'route:' + name ].concat(args)
      router.trigger 'route', name, args
      Backbone.history.trigger 'route', router, name, args
      return
    ), this
    this
  _addAppRoute: (controller, route, methodName) ->
    if @options.scope
      route = @options.scope + '/' + route
    Marionette.AppRouter::_addAppRoute.apply this, [
      controller
      route
      methodName
    ]
    return
  navigate: (fragment, options) ->

    ### jshint maxcomplexity: 11 ###

    options = options or {}
    current_fragment = Backbone.history.fragment
    scope =
      if _.isFunction @options.scope then @options.scope()
      else @options.scope
    defaults = {}
    re = undefined

    ### jshint maxdepth: 4 ###

    if scope
      if fragment
        # prepend scope to fragment
        fragment = scope + '/' + fragment
        # if current URL ends in scope, this is additive, so set replace: true
        # we only do this if options.replace isn't already set to false (using _.defaults below)
        re = new RegExp(scope + '/?$', 'i')
        if current_fragment.match(re)
          defaults.replace = true
      else
        # fragment is empty, use scope as fragment
        # this allows you to pass an empty string to reset URL to scope
        fragment = scope
      # validate that requested URL is in scope
      # use `force: true` to override this scope check
      re = new RegExp(scope, 'i')
      if !current_fragment.match(re)
        if !options.force
          console.error 'Tab URL is out of scope.', scope, current_fragment
          return this
    # if URL already exists in fragment, don't overwrite URL
    # use `force: true` to force overwrite
    re = new RegExp(fragment)
    if current_fragment.match(re)
      # console.log('URL is already in place, no need to write');
      if !options.force
        return this
    # if URL is the same, but case is different, just replace the history state
    # e.g. navigate to /mixedcase/collections, URL will be updated to /MixedCase/collections
    # but it won't add an additional state to the history, so back button still works
    re = new RegExp(fragment + '/?$', 'i')
    if current_fragment.match(re)
      defaults.replace = true
    # apply our defaults to the passed options
    # e.g. if replace is explicitly set to false, then we can't override it
    _.defaults options, defaults
    Marionette.AppRouter::navigate.apply this, [
      fragment
      options
    ]
  destroy: ->
    # console.log('destroy router for scope', this.options.scope);
    # console.log('Backbone.history.handlers.length', Backbone.history.handlers.length);
    Backbone.history.handlers = _.filter(Backbone.history.handlers, ((handler) ->
      handler.router != this
    ), this)
    # console.log('Backbone.history.handlers.length', Backbone.history.handlers.length);
    return

module.exports = Router
