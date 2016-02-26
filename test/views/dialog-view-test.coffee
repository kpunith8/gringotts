define (require) ->
  DialogView = require 'views/dialog-view'

  describe 'DialogView', ->
    title = 'Secret Operation'
    text = 'Are you ready to know?'
    view = null
    clickSpy = null

    beforeEach ->
      sinon.stub $.fn, 'modal'
      clickSpy = sinon.spy()
      view = new DialogView {
        title, text,
        buttons: [
          {text: 'Yes', className: 'btn-action', click: clickSpy}
          {text: 'No', className: 'btn-cancel'}
        ]
      }
      view.render()

    afterEach ->
      view.dispose() unless view.disposed
      $.fn.modal.restore()

    it 'should have title set', ->
      expect(view.$ '.modal-title').to.have.text title

    it 'should have text set', ->
      expect(view.$ '.modal-body').to.have.text text

    it 'should have buttons renderred', ->
      expect(view.$ '.btn.btn-action').to.exist.and.to.have.text 'Yes'
      expect(view.$ '.btn.btn-cancel').to.exist.and.to.have.text 'No'

    context 'on click', ->
      beforeEach ->
        view.$('.btn.btn-action').trigger 'click'

      it 'should invoke click handler', ->
        expect(clickSpy).to.have.been.calledWith sinon.match.object
