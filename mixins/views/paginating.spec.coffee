import Chaplin from 'chaplin'
import ActiveSyncMachine from '../models/active-sync-machine'
import Paginated from '../models/paginated'
import Paginating from './paginating'
import Templatable from './templatable'
import templateMock from './paginating.spec.hbs'

class ItemViewMock extends Chaplin.View
  tagName: 'tr'
  className: 'test-item'
  getTemplateFunction: -> -> '<td><td><td>'

class PaginatedCollectionMock extends Paginated ActiveSyncMachine \
    Chaplin.Collection
  DEFAULTS: _.extend {}, @::DEFAULTS, per_page: 10
  urlRoot: '/test'
  syncKey: 'itemsList'
  ignoreKeys: ['bad']

class PaginatingViewMock extends Templatable Paginating Chaplin.CollectionView
  loadingSelector: '.loading'
  itemView: ItemViewMock
  listSelector: 'tbody'
  template: templateMock

describe 'Paginating mixin', ->
  sandbox = null
  collection = null
  view = null
  infinite = false
  count = 101
  itemList = ({} for i in [0..101])

  beforeEach ->
    sandbox = sinon.createSandbox useFakeServer: true
    sandbox.stub(Chaplin.utils, 'reverse').callsFake (path, params, query) ->
      "#{path}?#{Chaplin.utils.querystring.stringify query}"
    collection = new PaginatedCollectionMock()
    collection.infinite = infinite
    view = new PaginatingViewMock {routeName: 'test', collection}
    sandbox.server.respondWith [200, {}, JSON.stringify {
      next_page_id: 'abcdef'
      count: count
      itemsList: itemList
    }]
    p = collection.fetchWithQuery {bad: 'something'}, async: true
    sandbox.server.respond()
    p

  afterEach ->
    sandbox.restore()
    collection.dispose()
    view.dispose()

  it 'should be instantiated', ->
    expect(view).to.be.an.instanceOf PaginatingViewMock

  it 'should render pagination controls', ->
    expect(view.$ '.pagination-controls').to.exist.and
      .to.have.class "#{view.cid}"

  it 'should render links correctly', ->
    $link_prev = view.$ '.pagination-controls a.prev-page'
    $link_next = view.$ '.pagination-controls a.next-page'
    expect($link_prev).to.have.attr 'disabled'
    expect($link_prev).to.have.attr 'href', 'test?'
    expect($link_next).to.not.have.attr 'disabled'
    expect($link_next).to.have.attr 'href', 'test?page=2'

  it 'should render range string', ->
    expect(view.$ '.pagination-range').to.have.text '1-10 of 101'

  context 'changing to next page', ->
    beforeEach ->
      collection.fetchWithQuery page: 3

    it 'should render links correctly', ->
      $link_prev = view.$ '.pagination-controls a.prev-page'
      $link_next = view.$ '.pagination-controls a.next-page'
      expect($link_prev).to.not.have.attr 'disabled'
      expect($link_prev).to.have.attr 'href', 'test?page=2'
      expect($link_next).to.not.have.attr 'disabled'
      expect($link_next).to.have.attr 'href', 'test?page=4'

    it 'should render range string', ->
      expect(view.$ '.pagination-range').to.have.text '21-30 of 101'

  context 'changing to last page', ->
    beforeEach ->
      collection.fetchWithQuery page: 11

    it 'should render links correctly', ->
      $link_prev = view.$ '.pagination-controls a.prev-page'
      $link_next = view.$ '.pagination-controls a.next-page'
      expect($link_prev).to.not.have.attr 'disabled'
      expect($link_prev).to.have.attr 'href', 'test?page=10'
      expect($link_next).to.have.attr 'disabled'
      expect($link_next).to.have.attr 'href', 'test?page=11'

    it 'should render range string', ->
      expect(view.$ '.pagination-range').to.have.text '101-101 of 101'

  context 'when count is equal to number of pages * page count', ->
    before ->
      count = 100
      itemsList = ({} for i in [0..100])

    it 'should render range string', ->
      expect(view.$ '.pagination-range').to.have.text '1-10 of 100'
  
  context 'when count is less than the number of pages * page count', ->
    before ->
      count = 5
      itemsList = ({} for i in [0..5])
    
    it 'should render range string', ->
      expect(view.$ '.pagination-range').to.have.text '1-5 of 5'

  context 'infinite pagination', ->
    before ->
      infinite = true

    after ->
      infinite = false

    it 'should render links correctly', ->
      $link_prev = view.$ '.pagination-controls a.prev-page'
      $link_next = view.$ '.pagination-controls a.next-page'
      expect($link_prev).to.have.attr 'disabled'
      expect($link_prev).to.have.attr 'href', 'test?'
      expect($link_next).to.not.have.attr 'disabled'
      expect($link_next).to.have.attr 'href', 'test?page=abcdef'

    it 'should render range string', ->
      expect(view.$ '.pagination-range').to.have.text ''

  context 'on fetching start', ->
    promise = null

    beforeEach ->
      promise = collection.fetchWithQuery {page: 2}, async: yes
      return

    it 'should show loading', ->
      expect(view.$loading).to.not.have.css 'display', 'none'

    it 'should remove all items', ->
      expect(view.$ '.test-item').to.not.exist

    context 'on fetch finish', ->
      beforeEach ->
        sandbox.server.respondWith [200, {}, JSON.stringify {
          count: 101
          itemsList: ({} for i in [0..10])
        }]
        sandbox.server.respond()
        promise

      it 'should hide loading', ->
        expect(view.$loading).to.have.css 'display', 'none'

      it 'should have new items', ->
        expect(view.$ '.test-item').to.exist
