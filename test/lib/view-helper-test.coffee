define (require) ->
  handlebars = require 'handlebars'
  utils = require 'lib/utils'
  viewHelper = require 'lib/view-helper'

  describe 'ViewHelper', ->
    hbsOptions = null

    beforeEach ->
      hbsOptions = {
        fn: ->
        inverse: ->
      }
      sinon.stub hbsOptions, 'fn'
      sinon.stub hbsOptions, 'inverse'

    afterEach ->
      hbsOptions = null

    # Handlebars always passes a final argument to helpers, that's why we pass
    # an empty object in the tests.
    context 'URL helper', ->
      beforeEach ->
        sinon.stub utils, 'reverse', -> ''
      afterEach ->
        utils.reverse.restore()

      it 'should work without arguments', ->
        handlebars.helpers.url {}
        expect(utils.reverse).to.be.calledOnce

      it 'should properly format URLs with params', ->
        handlebars.helpers.url 'route', 'params', {}
        expect(utils.reverse).to.be.calledWith 'route', ['params']

      it 'should properly format URLs with params as object', ->
        handlebars.helpers.url 'route', {p1:1, p2:2}, {}
        expect(utils.reverse).to.be.calledWith 'route', {p1:1, p2:2}

      it 'should properly format URLs with params as array', ->
        handlebars.helpers.url 'route', ['param1', 'param2'], {}
        expect(utils.reverse).to.be.calledWith 'route', ['param1', 'param2']

      it 'should properly format URLs without params', ->
        handlebars.helpers.url 'path', {}
        expect(utils.reverse).to.be.calledWith 'path'

      it 'should be able to be called without a query', ->
        handlebars.helpers.url 'path', 5, {}
        expect(utils.reverse).to.be.calledWith 'path', [5]

      it 'should pass the query along', ->
        handlebars.helpers.url 'starbuck', null, 'rank=lt', {}
        expect(utils.reverse).to.be.calledWith 'starbuck', null, 'rank=lt'

      it 'should pass the handlebars hash into query', ->
        handlebars.helpers.url 'route', 5, null, hash: p1: 1
        expect(utils.reverse).to.be.calledWith 'route', [5], p1: 1

    context 'icon helper', ->
      icon = null
      first = null
      second = null

      beforeEach ->
        icon = handlebars.helpers.icon first or 'triangle', second

      afterEach ->
        icon = null

      it 'should create HTML element', ->
        expect($ icon.string).to.have.class 'icon-triangle'

      context 'with a string', ->
        before -> second = 'rectangle'
        after -> second = null

        it 'should add classes', ->
          expect($ icon.string).to.have.class 'rectangle'

      context 'with an object', ->
        before ->
          second = title: 'My Title'

        after ->
          second = null

        it 'should add attributes', ->
          expect($ icon.string).to.have.attr 'title', 'My Title'

      context 'with a complex name', ->
        before -> first = 'my   sweet dreamy circle'
        after -> first = null

        it 'should add all classes', ->
          expect($ icon.string).to.have.class('my').and.have.class('sweet')
            .and.have.class('dreamy').and.have.class('icon-circle')

      it 'should return nothing if name is not set', ->
        icon = handlebars.helpers.icon()
        expect(icon).to.be.undefined

    context 'mail helper', ->
      it 'should format date correctly with default input format', ->
        timeStamp = handlebars.helpers.dateFormat '1969-12-31', 'l', {}
        expect(timeStamp).to.equal '12/31/1969'

      it 'should format date correctly with custom input format', ->
        timeStamp = handlebars.helpers.dateFormat '26/11/1982', 'l',
          'DD/MM/YYYY', {}
        expect(timeStamp).to.equal '11/26/1982'

      it 'should return nothing if input value is falsy', ->
        timeStamp = handlebars.helpers.dateFormat null, 'l', {}
        expect(timeStamp).to.be.undefined

    context 'mail helper', ->
      $el = null

      beforeEach ->
        $el = $ handlebars.helpers.mailTo('<hax>').string

      it 'should escape the email', ->
        expect($el).to.contain '&lt;hax&gt;'

      it 'should create the HTML element', ->
        expect($el).to.match 'a'
        expect($el.attr 'href').to.contain 'mailto'

    context 'and operator', ->
      context 'with fn and inverse blocks', ->
        it 'should call inverse when containing a falsy value', ->
          handlebars.helpers.and true, false, true, hbsOptions
          expect(hbsOptions.inverse).to.be.calledOnce

        it 'should call fn when containing no falsy values', ->
          handlebars.helpers.and true, true, 1, 'yes', hbsOptions
          expect(hbsOptions.fn).to.be.calledOnce

      context 'without fn and inverse blocks', ->
        it 'should return false when containing a falsy value', ->
          expect(handlebars.helpers.and true, true, false).to.eql false

        it 'should return true when containing all truthy values', ->
          expect(handlebars.helpers.and true, 'yes', 1).to.eql.true

    context 'concat strings', ->
      result = null

      beforeEach ->
        result = handlebars.helpers.concat 'str1', 'str2', 'str3', hbsOptions

      afterEach ->
        result = null

      it 'should concat strings', ->
        expect(result).to.eql 'str1str2str3'

    context 'ifequal helper', ->
      context 'with fn and inverse blocks', ->
        it 'should be true for equal values', ->
          handlebars.helpers.ifequal 100, 100, hbsOptions
          expect(hbsOptions.fn).to.be.calledOnce

        it 'should be false for non-equal values', ->
          handlebars.helpers.ifequal 100, 200, hbsOptions
          expect(hbsOptions.inverse).to.be.calledOnce

      context 'without fn and inverse blocks', ->
        it 'should be true for equal values', ->
          expect(handlebars.helpers.ifequal 100, 100).to.be.true

        it 'should be false for non-equal values', ->
          expect(handlebars.helpers.ifequal 100, 200).to.be.false

    context 'unlessEqual helper', ->
      context 'with fn and inverse blocks', ->
        it 'should be true for non-equal values', ->
          handlebars.helpers.unlessEqual 100, 200, hbsOptions
          expect(hbsOptions.fn).to.be.calledOnce

        it 'should be false for equal values', ->
          handlebars.helpers.unlessEqual 100, 100, hbsOptions
          expect(hbsOptions.inverse).to.be.calledOnce

      context 'without fn and inverse blocks', ->
        it 'should be true for non-equal values', ->
          expect(handlebars.helpers.unlessEqual 100, 200).to.be.true

        it 'should be false for equal values', ->
          expect(handlebars.helpers.unlessEqual 100, 100).to.be.false

    context 'array helper', ->
      it 'should return array for arguments', ->
        result = handlebars.helpers.array 10, 55, 647, hbsOptions
        expect(result).to.eql [10, 55, 647]

    context 'object helper', ->
      it 'should return object for hash', ->
        result = handlebars.helpers.object null,
          _.extend {}, hbsOptions, hash: {a: 10, b: 55}
        expect(result).to.eql {a: 10, b: 55}
