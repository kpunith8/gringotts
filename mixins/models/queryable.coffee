import Chaplin from 'chaplin'
import Backbone from 'backbone'
import {compress, superValue} from '../../lib/utils'
import helper from '../../lib/mixin-helper'

###*
  * Adds a capability of scoping a Collection or Model url with custom query
  * params for every sync request.
  * Adds a persistent query state storage to keep track of all parameters that
  * has to be added to the url.
  * Adds support of default query state parameter values and translation
  * of client param keys to server onces. Also with ability to ignore some
  * of the keys.
  * If there are multiple instances of a Collection or a Model assined to
  * views on the same screen, please use prefix property to distringuish
  * query state params before passing it to Chaplin routing system.
  * @param  {Model|Collection} superclass
###
export default (superclass) -> helper.apply superclass, (superclass) -> \

class Queryable extends superclass
  helper.setTypeName @prototype, 'Queryable'

  ###*
    * Default query params hash for this collection.
    * Override when necessary.
  ###
  DEFAULTS: {}

  ###*
    * Used to map local param names to queryparam server attrs
    * Override when necessary.
  ###
  DEFAULTS_SERVER_MAP: {}

  ###*
    * Query state storage for the params.
    * @type {Object}
  ###
  query: null

  ###*
    * Custom string keyword to scope input query keys. Useful if there is
    * a case of using two or more instances of a Model assigned to views
    * on the browser page.
    * @type {String}
  ###
  prefix: null

  ###*
    * List of query keys to ignore when generating a query hash.
    * @type {Array}
  ###
  ignoreKeys: null

  initialize: ->
    helper.assertModelOrCollection this
    unless typeof @url is 'function'
      throw new Error 'Please use urlRoot instead
        of url as a URL property for syncing.'
    super arguments...
    @query = {}

  ###*
    * Generates a query hash from the current query and given overrides.
    * @param  {Object} opts = {} inclDefaults - adds default query
    *                            values into result, it is false by default.
    *                          inclIgnored - adds ignored query
    *                            values into result, it's true by default.
    *                          usePrefix - adds prefix string into query
    *                            property key, it is true by default.
    *                          overrides - optional state overrides.
    * @return {Object}         Combined query
  ###
  getQuery: (opts = {}) ->
    query = _.extend {}, @DEFAULTS, @query, opts.overrides
    # make sure only local properties are being passed in
    unless _.isEmpty _.intersection _.keys(query)
        , _.keys @DEFAULTS_SERVER_MAP
      throw new Error 'Pass in only local query properties.'
    query = @stripEmptyOrDefault query, opts
    # add prefixes and include alien values if requested
    if @prefix and (not _.isBoolean(opts.usePrefix) or opts.usePrefix)
      query = _(query).mapKeys (value, key) => "#{@prefix}_#{key}"
        .extend(@alienQuery).value()
    if _.isBoolean(opts.inclIgnored) and not opts.inclIgnored
      query = _.omit query, @ignoreKeys
    query

  ###*
    * Sets current query.
    * @param {String|Object} query  Query params for the new query
    * @return {Array}               Array of changed value keys.
  ###
  setQuery: (query) ->
    if _.isString query
      @setQueryString query
    else
      @setQueryHash query

  ###*
    * Sets current query in string format.
    * @param {String}  query   Queryparams in string format "a=b&c=d"
    * @return {Array}          Array of changed value keys.
  ###
  setQueryString: (query = '') ->
    @setQueryHash Chaplin.utils.querystring.parse query

  ###*
    * Sets current query in object format.
    * @param {Object}  query   Query params in object format {a: 'b', c: 'd'}
    * @return {Array}          Array of changed value keys.
  ###
  setQueryHash: (query = {}) ->
    unless _.isObject query
      throw new Error 'New query should be String or Object'
    newQuery = @stripEmptyOrDefault @unprefixKeys query
    diff = @queryDiff @query, newQuery
    if diff.length
      @query = newQuery
      @trigger 'queryChange', {@query, diff}, this
      diff
    else
      null

  ###*
    * Applies query params and fetch new data if params changed
    * (and not part of ignored list) or if this is a first time fetching.
    * @param  {String|Object} query    Query params for the new query.
    * @param  {Object}        options  Set of options for fetch method.
    * @return {$.Deferred}
  ###
  fetchWithQuery: (query, options) ->
    changedKeys = @setQuery query
    queryChanged = changedKeys and
      (not @ignoreKeys or
        not _.every changedKeys, (key) => @ignoreKeys.indexOf(key) >= 0)
    if queryChanged or @isUnsynced()
      @fetch options
    else
      $.Deferred().resolve()

  ###*
    * Strips the query from all undefined or default values
  ###
  stripEmptyOrDefault: (query, opts = {}) ->
    query = _.pickBy query, (value, key) =>
      value isnt undefined and (opts.inclDefaults or \
        not _.isEqual compress(@DEFAULTS[key]), compress value)

  ###*
    * Saves all alien values (without prefixes) into a separete hash
    * (to return on getQuery()). Renames prefixed keys into normal form.
    * @return {Object}
  ###
  unprefixKeys: (query) ->
    return query unless @prefix
    @alienQuery = {}
    query = _(query).pickBy (value, key) =>
      if isAlien = key.indexOf?(@prefix) < 0
        @alienQuery[key] = value
      return not isAlien
    .mapKeys (value, key) => key.replace "#{@prefix}_", ''
    .value()

  ###*
    * Returns URL with collection query params.
    * @returns {String}
  ###
  url: ->
    base = @urlRoot or superValue(this, 'url', _.isString) or super()
    throw new Error 'Please define url or urlRoot
      when implementing a queryable model or collection' unless base
    base = if _.isFunction(base) then base.apply(this) else base
    query = @getQuery inclDefaults: yes, inclIgnored: no, usePrefix: no
    # convert from local query keys to server query keys
    query = _.mapKeys query, (value, key) =>
      _.invert(@DEFAULTS_SERVER_MAP)[key] or key
    queryString = Chaplin.utils.querystring.stringify query
    @urlWithQuery base, queryString

  ###*
    * Combines URL base with query params.
    * @param  {String|Array|Object} base Base part of the URL, it supported
    *                                    in form of Array (of URLs), Object
    *                                    (Hash of URLs) or String (just URL).
    * @param  {String} queryString       Query params string
    * @return {String|Array|Object}      A new instance of amended base.
  ###
  urlWithQuery: (base, queryString) ->
    url = base
    if queryString
      if _.isString base
        url = "#{base}?#{queryString}"
      else if _.isArray(base) and base.length > 0
        bases = _.clone base
        bases[0] = "#{_.head(bases)}?#{queryString}"
        url = bases
      else if _.isObject(base) and keys = _.keys base
        bases = _.clone base
        firstKey = _.head keys
        bases[firstKey] = "#{bases[firstKey]}?#{queryString}"
        url = bases
    url

  ###*
    * Returns difference between two objects.
    * @return {Array}  Array of different value keys.
  ###
  queryDiff: (queryA, queryB) ->
    diffA = _.keys _.pickBy queryA, (v, k) -> not _.isEqual queryB[k], v
    diffB = _.keys _.pickBy queryB, (v, k) -> not _.isEqual queryA[k], v
    difference = _.union diffA, diffB

  class QueryableProxy
    _.extend @prototype, Backbone.Events

    disposed: false

    constructor: (queryable) ->
      @getQuery = _.bind queryable.getQuery, queryable
      @listenTo queryable, 'queryChange', (info) ->
        @trigger 'queryChange', info, this
      @listenTo queryable, 'dispose', -> @dispose()

    dispose: ->
      delete @getQuery
      @stopListening()
      @off()
      @disposed = yes
      Object.freeze? this

  ###*
    * A simple proxy object with only getQuery method to pass around.
    * @return {Object}
  ###
  proxyQueryable: ->
    new QueryableProxy this
