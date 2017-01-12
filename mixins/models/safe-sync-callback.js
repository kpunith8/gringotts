(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(function(require) {
    var helper;
    helper = require('../../lib/mixin-helper');

    /**
     * This mixin prevent errors when sync/fetch callback executes after
      * route change when model is disposed.
     */
    return function(superclass) {
      var SafeSyncCallback;
      return SafeSyncCallback = (function(superClass) {
        extend(SafeSyncCallback, superClass);

        function SafeSyncCallback() {
          return SafeSyncCallback.__super__.constructor.apply(this, arguments);
        }

        helper.setTypeName(SafeSyncCallback.prototype, 'SafeSyncCallback');

        SafeSyncCallback.prototype.initialize = function() {
          helper.assertModelOrCollection(this);
          return SafeSyncCallback.__super__.initialize.apply(this, arguments);
        };

        SafeSyncCallback.prototype.sync = function() {
          this.safeSyncHashCallbacks.apply(this, arguments);
          return this.safeSyncPromiseCallbacks(SafeSyncCallback.__super__.sync.apply(this, arguments));
        };


        /**
         * Piggies back off the AJAX option hash which the Backbone
          * server methods (such as `fetch` and `save`) use.
         */

        SafeSyncCallback.prototype.safeSyncHashCallbacks = function(method, model, options) {
          if (!options) {
            return;
          }
          return _.each(['success', 'error', 'complete'], (function(_this) {
            return function(cb) {
              var callback, ctx;
              callback = options[cb];
              if (callback) {
                ctx = options.context || _this;
                return options[cb] = function() {
                  if (!_this.disposed) {
                    return callback.apply(ctx, arguments);
                  }
                };
              }
            };
          })(this));
        };


        /**
         * Filters deferred calbacks and cancels chain if model is disposed.
         */

        SafeSyncCallback.prototype.safeSyncPromiseCallbacks = function($xhr) {
          var deferred, filter;
          if (!$xhr) {
            return;
          }
          filter = (function(_this) {
            return function() {
              if (_this.disposed) {
                $xhr.errorHandled = true;
                return _this.safeSyncDeadPromise();
              } else {
                return $xhr;
              }
            };
          })(this);
          deferred = $xhr.then(filter, filter, filter).promise();
          deferred.abort = function() {
            return $xhr.abort();
          };
          return deferred;
        };


        /**
         * A promise that never resolved, so niether of callbacks is called.
         */

        SafeSyncCallback.prototype.safeSyncDeadPromise = function() {
          return $.Deferred().promise();
        };

        return SafeSyncCallback;

      })(superclass);
    };
  });

}).call(this);
