define (require) ->
  helper = require '../../lib/mixin-helper'
  FilterSelection = require '../../models/filter-selection'
  FilterInputView = require '../../views/filter-input-view'
  Routing = require './routing'

  isPerhapsSyncedDeep = (collection) ->
    if _.isFunction collection.isSyncedDeep
    then collection.isSyncedDeep() else yes

  ###*
   * Helps initialize and sync the filter selection state of the FilterInputView
   * control and the underlying CollectionView's queryable collection.
  ###
  (superclass) -> class Filtering extends Routing superclass
    helper.setTypeName @prototype, 'Filtering'
    optionNames: @::optionNames.concat ['filterGroups']
    filterSelection: FilterSelection

    filteringIsActive: ->
      @filterSelection and @filterGroups

    initialize: ->
      helper.assertViewOrCollectionView this
      super
      @filterSelection = new @filterSelection()
      @addFilterSelectionListeners()

    render: ->
      super
      if @filteringIsActive()
        @subview 'filtering-control', new FilterInputView
          el: @$ '.filtering-control[data-filter-input]'
          collection: @filterSelection
          groupSource: @filterGroups
      @updateFilterSelection()

    onBrowserQueryChange: ->
      super
      @updateFilterSelection()

    updateFilterSelection: ->
      return unless @filteringIsActive()
      if isPerhapsSyncedDeep @filterGroups
        @resetFilterSelection @getBrowserQuery()
      else
        @listenTo @filterGroups, 'syncDeep', ->
          @resetFilterSelection @getBrowserQuery()

    resetFilterSelection: (obj) ->
      @removeFilterSelectionListeners()
      @filterSelection.fromObject obj, @filterGroups
      @addFilterSelectionListeners()

    addFilterSelectionListeners: ->
      @listenTo @filterSelection, 'update', @onFilterSelectionUpdate
      @listenTo @filterSelection, 'reset', @onFilterSelectionUpdate

    removeFilterSelectionListeners: ->
      @stopListening @filterSelection, 'update', @onFilterSelectionUpdate
      @stopListening @filterSelection, 'reset', @onFilterSelectionUpdate

    onFilterSelectionUpdate: ->
      query = _.defaults @filterSelection.toObject(),
        _.zipObject @filterGroups.pluck 'id'
      @setBrowserQuery _.extend query, page: 1
