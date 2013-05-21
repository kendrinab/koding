class FeederResultsController extends KDViewController

  constructor:(options = {}, data)->

    options.view                or= new FeederTabView hideHandleCloseIcons : yes
    options.paneClass           or= KDTabPaneView
    options.itemClass           or= KDListItemView
    options.listControllerClass or= KDListViewController
    options.onboarding          or= null

    super options,data

    @panes = {}
    @listControllers = {}

    @createTab name, filter for name, filter of options.filters

  loadView:(mainView)->

    mainView.hideHandleContainer()
    mainView.showPaneByIndex 0
    @utils.defer mainView.bound "_windowDidResize"

  openTab:(filter, callback)->
    tabView = @getView()
    pane = tabView.getPaneByName filter.name
    tabView.showPane pane
    callback? @listControllers[filter.name]

  createTab:(name, filter, callback)->
    {
      paneClass
      itemClass
      listControllerClass
      listCssClass
      onboarding
    } = @getOptions()

    tabView = @getView()

    @listControllers[name] = listController = new listControllerClass
      lazyLoadThreshold   : .75
      startWithLazyLoader : yes
      noItemFoundText     : filter.noItemFoundText or null
      viewOptions         :
        cssClass          : listCssClass
        type              : name
        itemClass         : itemClass

    forwardItemWasAdded = @emit.bind this, 'ItemWasAdded'

    listController.getListView().on 'ItemWasAdded', forwardItemWasAdded

    listController.on 'LazyLoadThresholdReached', =>
      @emit "LazyLoadThresholdReached"

    tabView.addPane @panes[name] = pane = new paneClass
      name : name

    pane.addSubView pane.listHeader = header = new CommonListHeader
      title : filter.optional_title or filter.title

    @putOnboardingView name if onboarding

    pane.addSubView pane.listWrapper = listController.getView()

    listController.scrollView?.on 'scroll', (event) =>
      if event.delegateTarget.scrollTop > 0
        header.setClass "scrolling-up-outset"
      else
        header.unsetClass "scrolling-up-outset"

    callback? listController

  putOnboardingView:(name)->
    pane         = @panes[name]
    tabView      = @getView()
    {onboarding} = @getOptions()
    header       = pane.listHeader

    view = if onboarding[name] instanceof KDView
      onboarding[name]
    else if typeof onboarding[name] is "string"
      new FeederOnboardingView pistachio : onboarding[name]

    return unless view

    appManager = @getSingleton("appManager")
    app        = appManager.getFrontApp()

    cb = ->
      view.bindTransitionEnd()
      view.setOption "name", name
      header.ready ->
        header.addSubView view
        view.setClass 'no-anim'
        view.$().css marginTop : -view.getHeight() - 50 # some
        view.unsetClass 'no-anim'
        KD.utils.wait 1000, ->
          view.once 'transitionend', tabView.bound "_windowDidResize"
          view.$().css marginTop : 1
          view.setClass 'in'

      view.on "OnboardingMessageCloseIconClicked", ->
        view.once 'transitionend', tabView.bound "_windowDidResize"
        view.$().css marginTop : -view.getHeight() - 50
        view.unsetClass 'in'
        # ux illusion: real values will be put
        # with _windowDidResize
        pane.listWrapper.setHeight window.innerHeight

    unless KD.isLoggedIn()
      KD.utils.wait 1000, cb
    else
      app.appStorage?.fetchValue "onboardingMessageIsReadFor#{name.capitalize()}Tab", (value)->
        return if value
        KD.utils.wait 1000, cb

