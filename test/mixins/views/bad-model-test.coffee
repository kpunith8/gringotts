define (require) ->
  Chaplin = require 'chaplin'
  utils = require 'lib/utils'
  BadModel = require 'mixins/views/bad-model'

  class ViewMock extends BadModel Chaplin.View

  describe 'BadModel', ->
    sandbox = null
    view = null
    model = null

    handle404Error = ->
      view.handleBadModel status: 404

    beforeEach ->
      sandbox = sinon.sandbox.create()
      model = new Chaplin.Model id: 56
      view = new ViewMock {model}
      sandbox.stub utils, 'redirectTo'
      sandbox.stub view, 'publishEvent'

    afterEach ->
      sandbox.restore()
      view.dispose()
      model.dispose()

    context 'informs user of error', ->
      defaultExpects = ->
        expect(utils.redirectTo.lastCall).to.be.calledWith ''
        expect(view.publishEvent.lastCall).to.be.calledWith 'notify'
        # Default message contains model ID.
        expect(view.publishEvent.lastCall.args[1]).to.be.contain model.id

      context 'for 403s', ->
        xhr = null

        beforeEach ->
          xhr = status: 403
          view.handle403 xhr

        afterEach ->
          xhr = null

        it 'should redirect and publish event', ->
          defaultExpects()

        it 'should mark xhr as errorHandled', ->
          expect(xhr).to.have.property('errorHandled').
            and.equal true

      context 'for 404s', ->
        xhr = null

        beforeEach ->
          xhr = status: 404
          view.handleAny xhr

        afterEach ->
          xhr = null

        it 'should redirect and publish event', ->
          defaultExpects()

        it 'should mark xhr as errorHandled', ->
          expect(xhr).to.have.property 'errorHandled', yes

    it 'should redirect to the specified route', ->
      view.badModelOpts = route: '66'
      handle404Error()
      expect(utils.redirectTo).to.be.calledWith '66'

    it 'should display specified message', ->
      view.badModelOpts = message: 'oops'
      handle404Error()
      expect(view.publishEvent.lastCall.args[1]).to.be.equal 'oops'

    it 'should invoke message as a method if appropriate', ->
      message = sinon.spy()
      view.badModelOpts = {message}
      handle404Error()
      expect(message).to.be.calledWith model

    it 'should invoke route as a method if appropriate', ->
      route = sinon.spy()
      view.badModelOpts = {route}
      handle404Error()
      expect(route).to.be.calledWith model

    it 'should pass route result to redirect call', ->
      view.badModelOpts = route: -> ['name', id: 1]
      handle404Error()
      args = utils.redirectTo.lastCall.args
      expect(args[0]).to.equal 'name'
      expect(args[1]).to.eql id: 1

    it 'should use default options for notify', ->
      handle404Error()
      defaults = view.publishEvent.lastCall.args[2]
      expect(defaults.classes).to.exist
