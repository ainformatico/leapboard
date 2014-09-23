# config
FADE_IN_TIME = 300
FADE_OUT_TIME = FADE_IN_TIME
ACTION_HEIGHT = 180
SWIPE_THRESHOLD = 300
SCREEN_SCALE = 0.50
MIN_GESTURE_CIRCLES = 0.5
CIRCLE_GESTURE_DURATION = 400000
SECONDS_BETWEEN_ACTIONS = 1

#base
class Model extends Backbone.Model
class Collection extends Backbone.Collection
class CollectionView extends Marionette.CollectionView
class Layout extends Marionette.LayoutView

App = new Marionette.Application

Vent = new Backbone.Wreqr.EventAggregator

LeapController = new Leap.Controller(enableGestures: true)

# global memory system
Memory = new Model

App.addRegions({
  mainRegion: '#main'
  pointerRegion: '#pointer'
  helpRegion: '#help'
  titleRegion: '#title'
})

#controller
class Controller extends Marionette.Controller
class StepsController extends Controller
  index: 0
  initialize: (steps) ->
    @view = App.mainRegion
    @steps = steps
    @loadFirst()
    @addListeners()

  addListeners: ->
    @listenTo Vent, 'stage:next', @onNextStage
    @listenTo Vent, 'stage:back', @onBackStage

  loadFirst: ->
    unless @index
      @load(@index)

  next: ->
    @load(++@index)

  back: ->
    @load(--@index)

  load: (stepNumber) ->
    if stepNumber >= 0 and stepNumber <= @steps.length
      # allow animation to be called before unloadint the stage
      if @view.currentView?
        @view.currentView.$el.fadeOut FADE_OUT_TIME, =>
          @_load(stepNumber)
      else
        @_load(stepNumber)
    else
      throw new Error('bad stage')

  _load: (stepNumber) ->
    view = new @steps[stepNumber]
    @view.show view

  onNextStage: ->
    @next()

  onBackStage: ->
    @back()


class AvatarCollection extends Collection

class StepModel extends Model

#static
users = [
  'janna-alexandrina',
  'darwin-shelley',
  'hewie-cal',
  'pamela-jocelyn',
  'philander-clarence',
  'tyrone-bob'
]


avatars = []

tickets = []
descriptions = []
descriptions.push "Bacon ipsum dolor sit amet frankfurter fatback doner, shankle andouille strip steak chicken pig tongue short loin turducken spare ribs ground round short ribs"
descriptions.push "Tenderloin ball tip corned beef swine, sausage t-bone beef rump. Pork belly bresaola tenderloin corned beef andouille kielbasa, filet mignon porchetta spare ribs sirloin"
descriptions.push "Prosciutto ribeye landjaeger, pig filet mignon ham fatback beef"
descriptions.push "Hamburger shankle ground round ribeye, swine pork bresaola drumstick spare ribs turducken"
descriptions.push "Tri-tip pork loin pig flank strip steak t-bone tongue rump capicola turducken venison bacon jerky"
descriptions.push "Tenderloin ball tip corned beef swine, sausage t-bone beef rump. Pork belly bresaola tenderloin corned beef andouille kielbasa, filet mignon porchetta spare ribs sirloin"

for i in [0..users.length - 1]
  avatars.push {
    id: i + 1,
    name: users[i]
  }

  tickets.push {
    id: i + 1,
    name: "project #{i + 1}"
    user: users[i]
    description: descriptions[i]
    status: 'success'
  }

gestureNames = ['tap', 'circle', 'swipe-up', 'swipe-right', 'swipe-down', 'swipe-left']
gestures = []

for gesture in gestureNames
  gestures.push {
    name: gesture,
    src: "#{gesture}.png"
  }

#views
class View extends Marionette.ItemView
  template: '#empty-tpl'

class TitleView extends View
  template: '#title-tpl'

  modelEvents: {
    'change' : 'render'
  }

  initialize: ->
    @model = new Model({content: ''})

  setText: (text) ->
    @model.set('content', text)

class HelpView extends View
  template: '#help-tpl'
  tagName: 'li'

class ImageView extends View
  template: '#image-tpl'
  tagName: 'li'

class TicketView extends View
  template: '#ticket-tpl'
  tagName: 'li'

  modelEvents: {
    'change': 'render'
  }

class PointerView extends View
  className: 'pointer'
  tagName: 'img'
  gestures: []

  initialize: ->
    @initGestures()
    @addListeners()
    @listenTo Vent, 'gesture', @handleGesture
    @listenTo Vent, 'gesture', @checkGesture

  initGestures: ->
    _.each @options.enabledGestures, (gesture) =>
      @gestures.push new gesture

  handleGesture: (gesture, frame) ->
    _.each @gestures, (gestureClass) ->
      if gestureClass.gesture == gesture.type
        gestureClass.handle(gesture, frame)

  addListeners: ->
    @listenTo Vent, 'frame', @onFrame

  onFrame: (frame) ->
    frame.hands.forEach (hand) ->
      pointer.setTransform(hand.screenPosition(), hand.roll())

  onRender: ->
    @el.src = '/img/hand.png'
    @el.width = 120
    @el.style.position = 'absolute'
    @el.onload = =>
      @setTransform([window.innerWidth/2, 0, 0], 0)

  getPosition: ->
    position = @$el.position()
    {
      x: position.left
      y: position.top
    }

  setTransform: (position, rotation) ->
    x = position[0] - @el.width  / 2

    # mouse style
    yz = position[2] * 100 / (window.innerHeight / 2)
    y = yz * window.innerHeight / 100

    # *buggy* screen style
    #y = @el.style.top  = position[1] - @el.height / 2 + 'px'

    @el.style.left = x + 'px'
    @el.style.top  = y + 'px'

    @el.style.transform = 'rotate(' + -rotation + 'rad)'

    @el.style.webkitTransform = @el.style.MozTransform = @el.style.msTransform =
    @el.style.OTransform = @el.style.transform

    Vent.trigger('pointer:position', x, y)

class HelpCollectionView extends CollectionView
  tagName: 'ul'
  childView: HelpView
  className: 'help'

  initialize: ->
    @baseCollection = @collection.clone()
    @listenTo Vent, 'show:help', @onShowHelp

  onShowHelp: (items) ->
    helpItems = _.map items, (item) =>
      @baseCollection.findWhere({name: item}).toJSON()

    @collection.reset(helpItems)

class MenuWithGestures extends CollectionView
  tagName: 'ul'
  backAction: true

  onShow: ->
    @$el
      .velocity({scale: 4}, {duration: 0})
      .velocity({scale: 1}, {duration: 300})

  initialize: ->
    @addListeners()
    @initCollection()
    @setHelp()
    @listenToGestures()
    if @backAction
      @listenTo Vent, 'gesture:circle', @onBack

  onBack: ->
    Vent.trigger 'stage:back'

  setHelp: ->
    throw Error 'Provide help'

  listenToGestures: ->
    throw Error 'Provide listeners'

  addListeners: ->
    @listenTo Vent, 'pointer:position', @handleHover

  initCollection: ->
    @collection = new Collection(tickets)

  checkCollision: (x, y, item) ->
    position = item.position()
    left = position.left
    top = position.top
    width = item.outerWidth()
    height = item.outerHeight()
    x > left and x < (left + width) and y > top and y < (top + height)

  handleHover: (x, y) ->
    items = @$(@itemsSelector)
    _.each items, (item) =>
      item = $(item)
      if @checkCollision(x, y, item)
        item
          .addClass('hover')
          .removeClass('nohover')
      else
        item
          .addClass('nohover')
          .removeClass('hover')

  getCollisionItem: (position) ->
    items = @$(@itemsSelector)
    _.find items, (item) =>
      item = $(item)
      @checkCollision(position.x, position.y, item)

  hideOthers: (rawItem) ->
    allItems = @$(@itemsSelector)
    noHoverItems = allItems.not('.hover')
    hoverItem = allItems.filter('.hover')

    hoverItem.velocity({
      scale: 4
    })

    noHoverItems.velocity({
      scale: 0
    })

  handleGesture: (gesture, frame, callback) ->
    pointerPosition = App.request 'pointer:position'
    item = @getCollisionItem(pointerPosition)
    if item
      if callback
        callback(item)
      else
        @triggerAction(item)
    else
      console.log 'preventing'

  getModel: (item) ->
    @collection.get(item.getAttribute('data-id'))

class SwipeGestureMenu extends MenuWithGestures

class KeyTapGestureMenu extends MenuWithGestures

class Gesture extends View
  actionHeight: ACTION_HEIGHT

  validateActionArea: (gesture, frame) ->
    if gesture.position
      # set as valid if the hand is close to the device
      gesture.position[1] < @actionHeight

  handle: (gesture, frame) ->
    if @validateActionArea(gesture)
      @checkGesture(gesture, frame)

  validateGesture: (gesture) ->
    gesture.type == @gesture

  makePointable: (gesture, frame) ->
    frame.pointable(gesture.pointableIds)

  fingerIsIndex: (pointable, frame) ->
    if frame.fingers[1]
      frame.fingers[1].id == pointable.id

  checkGesture: (gesture, frame) ->
    if @validateGesture(gesture, frame)
      if @canExecuteAgain()
        console.log @gesture, gesture
        @actionExecuted()
        @triggerMethod('gestureDetected', gesture, frame)
      else
        console.log 'preventing execution'

  canExecuteAgain: ->
    if @_actionStartedTime
      ((new Date - @_actionStartedTime)) > (SECONDS_BETWEEN_ACTIONS * 1000)
    else
      true

  actionExecuted: ->
    @_actionStartedTime = new Date

  onGestureDetected: (gesture, frame) ->
    Vent.trigger("gesture:#{gesture.type}", gesture, frame)

class KeyTapGesture extends Gesture
  gesture: 'keyTap'

  validateGesture: (gesture, frame) ->
    if super
      pointable = @makePointable(gesture, frame)
      @fingerIsIndex(pointable, frame)

class CircleGesture extends Gesture
  gesture: 'circle'
  backGestureCircles: MIN_GESTURE_CIRCLES
  backGestureDuration: CIRCLE_GESTURE_DURATION

  validateActionArea: (gesture) ->
    if gesture.center
      # set as valid if the hand is close to the device
      gesture.center[1] < @actionHeight

  validateGesture: (gesture, frame) ->
    super and @validateBackGesture(gesture, frame)

  validateBackGesture: (gesture, frame) ->
    pointable = @makePointable(gesture, frame)
    isIndex = @fingerIsIndex(pointable, frame)
    enoughCircles = gesture.progress > @backGestureCircles
    allowedDuration = gesture.duration > @backGestureDuration

    enoughCircles and allowedDuration and isIndex

class SwipeGesture extends Gesture
  gesture: 'swipe'

  getSwipeDirection: (gesture) ->
    # horizontal or vertical?
    isHorizontal = Math.abs(gesture.direction[0]) > Math.abs(gesture.direction[1])

    # right-left or up-down?
    if isHorizontal
      if gesture.direction[0] > 0
        swipeDirection = 'right'
      else
        swipeDirection = 'left'
    else #vertical
      if gesture.direction[1] > 0
        swipeDirection = 'up'
      else
        swipeDirection = 'down'

    console.log "direction: #{swipeDirection}"
    swipeDirection

  validateGesture: (gesture) ->
    # the gesture has been started
    if gesture.startPosition
      isSwipe = super
      isInRange = gesture.startPosition[0] < SWIPE_THRESHOLD and gesture.position[0] > -SWIPE_THRESHOLD
      isFinished = gesture.state == 'stop'

      isSwipe and isInRange and isFinished

  onGestureDetected: (gesture, frame) ->
    direction = @getSwipeDirection(gesture)
    Vent.trigger("gesture:swipe:#{direction}", gesture, frame)

class LoadingView extends View
  template: '#loader-tpl'
  className: 'loader-container'

  initialize: ->
    @listenTo Vent, 'gesture:keyTap ', @onKeyTap
    App.execute 'title:text', ''
    Vent.trigger('show:help', [])

  onKeyTap: ->
    @$el.fadeOut FADE_OUT_TIME, ->
      Vent.trigger 'stage:next'
      Vent.trigger 'stage:init'


class StepView extends View
  template: '#step-tpl'

class SelectorView extends KeyTapGestureMenu
  itemsSelector: '.avatar'
  childView: ImageView
  className: 'avatars'

  setHelp: ->
    Vent.trigger('show:help', ['tap'])

  onDomRefresh: ->
    App.execute 'title:text', 'User'

  listenToGestures: ->
    @listenTo Vent, 'gesture:keyTap', @handleGesture

  triggerAction: (item) ->
    @hideOthers()
    model = @getModel(item)
    Memory.set('currentUser', model)
    Vent.trigger 'stage:next'

  initCollection: ->
    # TODO: global reference
    @collection = new AvatarCollection(avatars)

class TicketList extends SwipeGestureMenu
  childView: TicketView
  className: 'tickets'
  itemsSelector: '.ticket-container'

  setHelp: ->
    Vent.trigger('show:help', ['swipe-left', 'circle', 'tap'])

  initCollection: ->
    # TODO: global reference
    @collection = new Collection(tickets)

  listenToGestures: ->
    @listenTo Vent, 'gesture:swipe:left', @handleGesture
    @listenTo Vent, 'gesture:swipe:right', @onSwipeRight
    @listenTo Vent, 'gesture:keyTap', @onKeyTap

  onSwipeRight: (gesture, frame) ->
    @handleGesture gesture, frame, (item) =>
      model = @getModel(item)
      model.set('status', 'error')

  onKeyTap: (gesture, frame) ->
    @handleGesture gesture, frame, (item) =>
      model = @getModel(item)
      model.set('user', Memory.get('currentUser').get('name'))

  triggerAction: (item) ->
    model = @getModel(item)
    @destroyModel(model, item)

  destroyModel: (model, item) ->
    $(item).slideUp FADE_OUT_TIME, ->
      model.trigger('destroy', model)

  onDomRefresh: ->
    App.execute 'title:text', 'Tickets'

pointer = new PointerView(enabledGestures: [KeyTapGesture, CircleGesture, SwipeGesture])

App.reqres.setHandler 'pointer:position', ->
  pointer.getPosition()

help = new HelpCollectionView(collection: new Collection(gestures))
App.helpRegion.show help

title = new TitleView
App.titleRegion.show title

App.commands.setHandler 'title:text', (text) ->
  title.setText(text)

Vent.on 'stage:init', ->
  App.pointerRegion.show pointer

#progress = new ProgressView
#App.progressRegion.show progress

steps = [LoadingView, SelectorView, TicketList]
controller = new StepsController(steps)


LeapController.on 'frame', (frame) ->
  Vent.trigger('frame', frame)

LeapController.on 'gesture', (gesture, frame) ->
  Vent.trigger('gesture', gesture, frame)

LeapController.use('screenPosition', {scale: SCREEN_SCALE})
LeapController.connect()
