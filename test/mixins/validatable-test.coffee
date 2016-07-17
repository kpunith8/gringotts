define (require) ->
  patterns = require('backbone_validation').patterns
  Validatable = require 'mixins/validatable'
  Model = require 'models/base/model'

  class MockModel extends Validatable Model
    validation:
      name:
        required: true
        pattern: 'name'
      email:
        required: true
        pattern: 'email'
      url:
        required: true
        pattern: 'url'
      guid:
        required: false
        pattern: 'guid'
      date:
        required: false
        fn: 'validateDate'

  describe 'Validatable', ->
    model = null
    isValid = null

    beforeEach ->
      model = new MockModel()

    afterEach ->
      model.dispose()

    it 'should not be valid by default', ->
      isValid = model.isValid true
      expect(isValid).to.be.false

    it 'should have errors of required', ->
      errors = model.validate()
      expect(errors).to.eql {
        name: 'Name is required'
        email: 'Email is required'
        url: 'Url is required'
      }

    context 'with wrong data', ->
      beforeEach ->
        model.set {
          name: '<johny>'
          email: 'example.com'
          url: 'domain'
          guid: '55555'
          date: 'is_this_a_date?'
        }

      it 'should have errors of invalid', ->
        errors = model.validate()
        expect(errors).to.eql {
          name: 'Name must be a valid name'
          email: 'Email must be a valid email'
          url: 'Url must be a valid url'
          guid: 'Guid must be a valid guid'
          date: 'Date must be a valid date'
        }

    context 'with valid data', ->
      beforeEach ->
        model.set {
          name: 'johny'
          email: 'test@example.com'
          url: 'domain.com'
          guid: '5e379ddf-130d-4813-b263-6371f30a97ca'
          date: '2016-07-17'
        }

      it 'should have errors of invalid', ->
        errors = model.validate()
        expect(errors).to.be.empty
