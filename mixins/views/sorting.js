(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  define(function(require) {
    var Routing, handlebars, helper, utils;
    handlebars = require('handlebars');
    utils = require('lib/utils');
    helper = require('../../lib/mixin-helper');
    Routing = require('./routing');

    /**
     * Adds sorting support to a CollectionView. It relies on Routing
     * mixin to get current route name and params to generate sorting links.
     * @param  {CollectionView} base superclass
     */
    return function(base) {
      var Sorting;
      return Sorting = (function(superClass) {
        extend(Sorting, superClass);

        function Sorting() {
          return Sorting.__super__.constructor.apply(this, arguments);
        }

        helper.setTypeName(Sorting.prototype, 'Sorting');


        /**
         * Name of handlebars partial with sorting controls.
         * @type {String}
         */

        Sorting.prototype.sortingPartial = 'sortTableHeader';


        /**
         * A hash of model attribute names and their string labels that are
         * expected to be sortable in the table.
         * @type {Object}
         */

        Sorting.prototype.sortableTableHeaders = null;

        Sorting.prototype.initialize = function() {
          helper.assertCollectionView(this);
          if (!this.sortableTableHeaders) {
            throw new Error('The sortableTableHeaders should be set for this view.');
          }
          Sorting.__super__.initialize.apply(this, arguments);
          if (!this.routeQueryable) {
            throw new Error('This view should have a collection with applied Queryable mixin.');
          }
          return this.listenTo(this.routeQueryable, 'queryChange', function(info) {
            return this.renderSortingControls();
          });
        };

        Sorting.prototype.getTemplateData = function() {
          return _.extend(Sorting.__super__.getTemplateData.apply(this, arguments), {
            sortInfo: this.getSortInfo()
          });
        };

        Sorting.prototype.render = function() {
          if (!this.routeName) {
            throw new Error("Can't render view when routeName isn't set");
          }
          return Sorting.__super__.render.apply(this, arguments);
        };

        Sorting.prototype.renderAllItems = function() {
          Sorting.__super__.renderAllItems.apply(this, arguments);
          return this.highlightColumns();
        };

        Sorting.prototype.getSortInfo = function() {
          var query;
          query = this.getBrowserQuery();
          if (!query.sort_by) {
            throw new Error('Please define a sort_by attribute within DEFAULTS');
          }
          return _.transform(this.sortableTableHeaders, (function(_this) {
            return function(result, title, column) {
              var nextOrder, order;
              order = column === query.sort_by ? query.order : '';
              nextOrder = order === 'asc' ? 'desc' : 'asc';
              result[column] = {
                viewId: _this.cid,
                attr: column,
                text: title,
                order: order,
                routeName: _this.routeName,
                routeParams: _this.routeParams,
                nextQuery: _this.routeQueryable.getQuery({
                  overrides: {
                    order: nextOrder,
                    sort_by: column
                  }
                })
              };
              return result;
            };
          })(this), {});
        };


        /**
         * Highlights with a css class currently sorted table column.
         */

        Sorting.prototype.highlightColumns = function() {
          var idx, query;
          query = this.getBrowserQuery();
          idx = this.$("th[data-sort=" + query.sort_by + "]").index();
          return this.$(this.listSelector + " " + this.itemView.prototype.tagName + " td").removeClass('highlighted').filter(":nth-child(" + (idx + 1) + ")").not('[colspan]').addClass('highlighted');
        };

        Sorting.prototype.renderSortingControls = function() {
          var sortInfo, template;
          sortInfo = this.getSortInfo();
          template = handlebars.partials[this.sortingPartial];
          if (!(sortInfo && template)) {
            return;
          }
          return this.$(".sorting-control." + this.cid).each((function(_this) {
            return function(i, el) {
              var $el, attr, classes;
              $el = $(el);
              attr = $el.attr('data-sort');
              classes = $el.removeClass("sorting-control " + _this.cid).attr('class');
              return $el.replaceWith(template({
                sortInfo: sortInfo,
                attr: attr,
                "class": classes
              }));
            };
          })(this));
        };

        return Sorting;

      })(utils.mix(base)["with"](Routing));
    };
  });

}).call(this);
