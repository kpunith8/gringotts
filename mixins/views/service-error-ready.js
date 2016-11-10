(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(function(require) {
    var helper;
    helper = require('../../lib/mixin-helper');
    return function(superclass) {
      var ServiceErrorReady;
      return ServiceErrorReady = (function(superClass) {
        extend(ServiceErrorReady, superClass);

        function ServiceErrorReady() {
          return ServiceErrorReady.__super__.constructor.apply(this, arguments);
        }

        helper.setTypeName(ServiceErrorReady.prototype, 'ServiceErrorReady');

        ServiceErrorReady.prototype.errorSelector = '.service-error';

        ServiceErrorReady.prototype.listen = {
          'unsynced collection': function() {
            if (!this.disposed) {
              return this.$(this.errorSelector).show();
            }
          },
          'syncing collection': function() {
            if (!this.disposed) {
              return this.$(this.errorSelector).hide();
            }
          },
          'synced collection': function() {
            if (!this.disposed) {
              return this.$(this.errorSelector).hide();
            }
          }
        };

        ServiceErrorReady.prototype.initialize = function() {
          helper.assertViewOrCollectionView(this);
          return ServiceErrorReady.__super__.initialize.apply(this, arguments);
        };

        return ServiceErrorReady;

      })(superclass);
    };
  });

}).call(this);
