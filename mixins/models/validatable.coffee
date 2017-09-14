moment = require 'moment'
backboneValidation = require 'backbone-validation'
helper = require '../../lib/mixin-helper'

backboneValidation.configure {
  labelFormatter: 'label'
}

# Override/extend default validation patterns
_.extend backboneValidation.patterns,
  name: /^((?!<\\?.*>).)+/
  email: /^[^@]+@[^@]+\.[^@]+$/
  domain: /[a-z0-9.\-]+\.[a-zA-Z]{2,}/
  url: ///
    https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}
    \b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)///
  guid: ///^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}
    -[89ab][0-9a-f]{3}-[0-9a-f]{12}$///

_.extend backboneValidation.messages,
  name: '{0} must be a valid name'
  guid: '{0} must be a valid guid'
  date: '{0} must be a valid date'
  domain: '{0} must be a valid domain'

# Expected date format from browser input[type=date] elements
BROWSER_DATE = ['MM/DD/YYYY', 'YYYY-MM-DD']

###*
  * Applies backbone.validation mixin to a Model.
  * Adds a validateDate function.
  * @param  {Backbone.Model} superclass
###
module.exports = (superclass) -> helper.apply superclass, (superclass) -> \

class Validatable extends superclass
  helper.setTypeName @prototype, 'Validatable'

  _.extend @prototype, _.extend {}, backboneValidation.mixin,
    # HACK force model validation if no args passed
    isValid: (option) ->
      backboneValidation.mixin.isValid.apply this, [option || true]
    # HACK until https://github.com/thedersen/backbone.validation/issues/232
    validate: ->
      error = backboneValidation.mixin.validate.apply this, arguments
      @validationError = error || null
      error

  initialize: ->
    helper.assertModel this
    super

  validateDate: (value, attr) ->
    if value and not moment(value, BROWSER_DATE).isValid()
      backboneValidation.messages.date.replace '{0}',
        backboneValidation.labelFormatters.label attr, this
