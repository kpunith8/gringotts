define (require) ->
  StateBindable = require 'mixins/state-bindable'
  StringTemplatable = require 'mixins/string-templatable'
  Model = require 'models/base/model'
  View = require 'views/base/view'

  class MockView extends StateBindable StringTemplatable View
    template: 'state-bindable-test'
    templatePath: 'test/templates'

  initialState = isDisabled: yes

  stateBindings =
    '#button':
      attributes: [
        name: 'disabled'
        observe: 'isDisabled'
      ]

  describe 'StateBindable', ->
    view = null

    expectations = ->
      it 'should set button disabled', ->
        expect(view.$ '#button').to.have.attr 'disabled'

      context 'on state attr change', ->
        beforeEach ->
          view.state.set 'isDisabled', no

        it 'should set button enabled', ->
          expect(view.$ '#button').to.not.have.attr 'disabled'

      context 'on view dispose', ->
        beforeEach ->
          view.dispose()

        it 'should dispose state model', ->
          expect(view.state.disposed).to.be.true

    context 'configs set directly', ->
      beforeEach ->
        MockView::initialState = initialState
        MockView::stateBindings = stateBindings
        view = new MockView()

      afterEach ->
        view.dispose()

      expectations()

    context 'configs set though function', ->
      beforeEach ->
        MockView::initialState = -> initialState
        MockView::stateBindings = -> stateBindings
        view = new MockView()

      afterEach ->
        view.dispose()

      expectations()
