(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(function(require) {
    var Chaplin, ErrorHandling, StringTemplatable, View;
    Chaplin = require('chaplin');
    StringTemplatable = require('../../mixins/views/string-templatable');
    ErrorHandling = require('../../mixins/views/error-handling');
    return View = (function(superClass) {
      extend(View, superClass);

      function View() {
        return View.__super__.constructor.apply(this, arguments);
      }

      View.prototype.autoRender = true;

      return View;

    })(ErrorHandling(StringTemplatable(Chaplin.View)));
  });

}).call(this);
