(function() {
  var AdequateTabs, root;

  AdequateTabs = (function() {
    function AdequateTabs() {}

    AdequateTabs.prototype.greeting = function() {
      return 'Hello World';
    };

    return AdequateTabs;

  })();

  root = typeof exports !== "undefined" && exports !== null ? exports : window;

  root.AdequateTabs = AdequateTabs;

}).call(this);
