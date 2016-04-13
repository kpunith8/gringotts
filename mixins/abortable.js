(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(function(require) {

    /**
     * Aborts the existing fetch request if a new one is being requested.
     */
    return function(superclass) {
      var Abortable;
      return Abortable = (function(superClass) {
        extend(Abortable, superClass);

        function Abortable() {
          return Abortable.__super__.constructor.apply(this, arguments);
        }

        Abortable.prototype.initialize = function() {
          Abortable.__super__.initialize.apply(this, arguments);
          if (!_.isFunction(this.isSyncing)) {
            throw new Error('Abortable mixin works only with ActiveSyncMachine');
          }
        };

        Abortable.prototype.fetch = function() {
          var $xhr, base;
          $xhr = Abortable.__super__.fetch.apply(this, arguments);
          if (this._currentXHR && this.isSyncing()) {
            if (typeof (base = this._currentXHR).abort === "function") {
              base.abort();
            }
          }
          return this._currentXHR = $xhr ? $xhr.always((function(_this) {
            return function() {
              return delete _this._currentXHR;
            };
          })(this)) : void 0;
        };

        return Abortable;

      })(superclass);
    };
  });

}).call(this);