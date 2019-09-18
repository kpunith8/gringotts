import helper from '../../lib/mixin-helper'
import Routing from './routing'
import partialTemplate from '../../templates/partials/pagination'

###*
  * Adds pagination support to a CollectionView. It relies on Routing
  * mixin to get current route name and params to generate pagination links.
  * @param  {CollectionView} base superclass
###
export default (superclass) -> helper.apply superclass, (superclass) -> \

class Paginating extends Routing superclass
  helper.setTypeName @prototype, 'Paginating'

  listen:
    'sync collection': ->
      # collection count could be updated
      @renderPaginatingControls()

  initialize: ->
    helper.assertCollectionView this
    super arguments...
    unless @routeQueryable
      throw new Error 'This view should have a collection with
        applied Queryable mixin.'
    @listenTo @routeQueryable, 'queryChange', (info) ->
      @renderPaginatingControls()

  ###*
    * Add the pageInfo context into the view template.
    * Render using {{> pagination pageInfo}}.
    * @return {object} Context for use within the template.
  ###
  getTemplateData: ->
    _.extend super(), pageInfo: @getPageInfo()

  render: ->
    unless @routeName
      throw new Error "Can't render view when routeName isn't set"
    super()

  getStats: (min, max, info) ->
    if I18n?
      I18n.t 'items.total', start: min, end: max, total: info.count
    else
      "#{[min, max].join '-'} of #{info.count}"

  getRangeString: (page, perPage, info) ->
    maxItems = info.pages * perPage
    max = Math.min info.count, page * perPage
    min = (page - 1) * perPage + 1
    min = Math.min min, max
    @getStats min, max, info

  # setup what the pagination template is expecting
  getPageInfo: ->
    infinite = @collection.infinite
    query = @getBrowserQuery()
    perPage = parseInt query.per_page
    page = if infinite then query.page else parseInt query.page
    info =
      viewId: @cid
      count: @collection.count
      page: page
      perPage: perPage
    if infinite
      info.pages = 1
      info.multiPaged = true
      info.prev = if page isnt 1 then 1 else 0
      info.next = @collection.nextPageId
    else
      info.pages = Math.ceil @collection.count / perPage
      info.multiPaged = @collection.count > perPage
      info.prev = if page > 1 then page - 1 else 0
      info.next = if page < info.pages then page + 1 else 0
      info.range = @getRangeString page, perPage, info
    options = inclDefaults: no, inclIgnored: no, usePrefix: yes
    info.nextQuery =
      if info.next
      then @getBrowserQuery _.extend {}, options, overrides: page: info.next
      else @getBrowserQuery options
    info.prevQuery =
      if info.prev
      then @getBrowserQuery _.extend {}, options, overrides: page: info.prev
      else @getBrowserQuery options

    info.routeName = @routeName
    info.routeParams = @routeParams
    info

  paginationPartial: ->
    partialTemplate

  renderPaginatingControls: ->
    pageInfo = @getPageInfo()
    template = @paginationPartial()
    return unless pageInfo and template
    @$(".pagination-controls.#{@cid}").each (i, el) ->
      $(el).replaceWith template pageInfo
