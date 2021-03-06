# This is a view with ability to display a notification
# and undo a server request by deferring it with a timeout.
#
# It requires a `model` with an `opts` attribute which should be
# an object with a `success` and `undo` key with a corresponding
# method.
#
# After `4ms`, it will remove the notification and execute the
# `success` method if provided. Pass in a `sticky` flag if you
# don't want the notification to dismiss. Sticky notifications
# only dismiss manually or on route.
#
# The action can be undone by providing a `undo()` method which
#  will be invoked when the associated element is clicked.
#
# If an associated model is provided in the `opts` object under
# the key `model`, it will listen for disposal and run `success`
# immediately.
#
# Classes can be added on an per instance basis with the `classes`
# key on `opts`.
#
# A `link` can be provided to append to the notification.
#
# A `click` handler can be provided which takes the form of an `object`
# with a key for `selector` and one for `handler` which are the arguments used
# by `@delegate`. If `undo` is true it will overwrite `click`.
#
# Fade speed, timeout length, undo selector, stickiness, whether navigate
# dismisses, link, click handler, and classes can be configured via
# overrriding of public properties.
import View from './base/view'
import undoTemplate from './notification-undo'
import template from './notification'

# Local reference for the timeout.
notificationTimeout = null

# ALL - Dismiss when navigating away from any route
# ROUTE - Dismiss when navigating away from main route
# But ignore query param changes
# e.g (/route?p=1 to /route?p=2)
DISMISS_METHOD =
  ALL: 'all'
  ROUTE: 'route'

export default class NotificationView extends View
  template: template
  tagName: 'li'
  className: 'alert alert-success alert-dismissable'
  optionNames: @::optionNames.concat [
    'undoSelector', 'fadeSpeed', 'reqTimeout'
  ]
  undoSelector: '.undo'
  fadeSpeed: 200
  reqTimeout: 4000
  dismissMethod: DISMISS_METHOD.ROUTE

  initialize: ->
    super arguments...
    @navigateDismiss()

  # Override to customize the undo element.
  getUndoElement: ->
    undoTemplate label: I18n?.t('notifications.undo') or 'Undo'

  # if `opts` has `navigateDismiss` then upon navigation the notification is
  # dismissed
  navigateDismiss: ->
    opts = @model.get('opts') or {}
    @dismissMethod = opts.dismissMethod if opts.dismissMethod
    if opts.navigateDismiss
      @subscribeEvent 'dispatcher:dispatch', (controller, params, route) ->
        if @dismissMethod is DISMISS_METHOD.ROUTE
          @dismissOnNavigation route
        else
          @dismiss

  # notifications should not be dismissed when navigating to
  # paths in the same prefixed namespace
  dismissOnNavigation: (route, path_level) ->
    path = route.path.split('?')[0]
    prevPath = route.previous?.path.split('?')[0]
    unless path is prevPath
      @dismiss()

  # Discard model when the view is removed.
  # `success` callback will execute when view is faded in `fadespeed` ms.
  #
  # Override to specify different behavior when the notification is closed.
  dismiss: ->
    return unless @$el
    @$el.removeClass 'in'
    # give some time for CSS fade effect to finish
    _.delay (=> @model.dispose() unless @disposed), @fadeSpeed

  # Display undo and start the timeout for the view and optional
  # `success` callback.
  render: ->
    super()
    opts = @model.get('opts') or {}
    # Limit undo to current change.
    if opts.undo
      # Only one action may be undone at any given time.
      $(@undoSelector).remove()
      opts.link = @getUndoElement()
    @$el.append opts.link if opts.link
    opts.deferred?.then => @dismiss()
    unless opts.sticky
      # Allow instance to specify timeout.
      timeout = opts.reqTimeout or @reqTimeout
      # Expose timeout for cancellation elsewhere.
      @model.timeout = notificationTimeout = window.setTimeout =>
        opts.success?()
        @dismiss()
      , timeout

  # Hooks up actions on the notification.
  attach: ->
    super arguments...
    @delegate 'click', '.close', (e) ->
      e.preventDefault()
      e.stopPropagation()
      @dismiss()
    # Commit to request when model is disposed.
    opts = @model.get('opts') or {}
    if opts.model
      @listenTo opts.model, 'dispose', ->
        window.clearTimeout notificationTimeout
        opts.success?()
        @dismiss()
    # This will overwrite other click handlers given in opts.
    if opts.undo
      opts.click =
        selector: @undoSelector
        handler: (e) ->
          e.preventDefault()
          window.clearTimeout notificationTimeout
          opts.undo()
          @dismiss()
    # You can pass in a selector and handler for a click event
    @delegate 'click', opts.click.selector, opts.click.handler if opts.click
    # Add specified classes on an instance basis.
    classes = opts.classes or 'alert-success'
    @$el.addClass classes
