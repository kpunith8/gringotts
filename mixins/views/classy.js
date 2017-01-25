(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(function(require) {
    var helper;
    helper = require('../../lib/mixin-helper');

    /**
     * Just another way to add custom css class to View element
     * without interfering with Backbone View's className.
     * @param  {Backbone.View} superclass
     */
    return function(superclass) {
      return helper.apply(superclass, function(superclass) {
        var Classy;
        return Classy = (function(superClass) {
          extend(Classy, superClass);

          function Classy() {
            return Classy.__super__.constructor.apply(this, arguments);
          }

          helper.setTypeName(Classy.prototype, 'Classy');

          Classy.prototype.classyName = null;

          Classy.prototype.initialize = function() {
            helper.assertViewOrCollectionView(this);
            return Classy.__super__.initialize.apply(this, arguments);
          };

          Classy.prototype.render = function() {
            var className;
            if (this.classyName) {
              className = this.$el.attr('class') || '';
              if (className !== '') {
                className += ' ';
              }
              if (!new RegExp("(^|\\s+)" + this.classyName + "(\\s+|$)", 'ig').test(className)) {
                this.$el.attr('class', "" + className + this.classyName);
              }
            }
            return Classy.__super__.render.apply(this, arguments);
          };

          return Classy;

        })(superclass);
      });
    };
  });

}).call(this);
