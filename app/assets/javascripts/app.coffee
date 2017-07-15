window.App ||= {}

App.init = ->
  $('[data-toggle=tooltip]').tooltip()

  $('.btn.btn-loading').click ->
    $(@).button('loading')

  Selectize = new App.Selectize()
  Selectize.init()

  Moment = new App.Moment()
  Moment.init()

App.initInternal = ->
  Accounting = new App.Accounting()
  Accounting.init()

  pdfViewers = $('.pdf-viewer')
  if pdfViewers.length > 0
    PDFJS.workerSrc = PDFJSWorkerPath
    for viewer in pdfViewers
      PDFViewer = new App.PDFViewer($(viewer))
      PDFViewer.init()

  Cable = new App.Cable()
  App.cable = Cable.consumer

  Timer = new App.Timer($('.current-timers'))
  Timer.init()

  new App.Notifications()

document.addEventListener 'turbolinks:load', ->
  App.init()
  App.initInternal() if AuthToken

$(document).on 'click', '[data-geolocation]', (ev) ->
  ev.preventDefault()
  GeoLocation = new App.GeoLocation($(ev.target))
  GeoLocation.start()

$(document).on 'click', 'a.disabled', (ev) ->
  ev.preventDefault()

$(document).on 'click', 'code[data-target]', (ev) ->
  $element = $(ev.target)
  $target = $($element.data('target'))
  $target.val($target.val() + $element.text())

document.addEventListener 'keydown', (e) ->
  return true if $('form') is undefined
  if navigator.platform.match("Mac")
    superKeyPressed = e.metaKey
  else
    superKeyPressed = e.ctrlKey
  if e.keyCode == 83 && superKeyPressed
    e.preventDefault()
    $('form:first').submit()
, false

$(document).on 'click', 'body > .container-fluid', ->
  $('.navbar-default .navbar-collapse').collapse('hide')

$(document).on 'show.bs.collapse', '.navbar-collapse', ->
  $('.navbar.navbar-default').css('left', '300px')
  $('body > .container-fluid').css('left', '300px')
  $('.navbar-collapse.in').not(this).collapse('hide')

$(document).on 'hide.bs.collapse', '.navbar-collapse', ->
  $('.navbar.navbar-default').css('left', '')
  $('body > .container-fluid').css('left', '')

$(document).on "upload:start", "form", (e) ->
  $(@).find("[type=submit]").attr("disabled", true)

$(document).on "upload:complete", "form", (e) ->
  if !$(@).find("input.uploading").length
    $(@).find("[type=submit]").removeAttr("disabled")

$(document).on "focus", ".modal input, .modal textarea, .modal select", ->
  $(@)[0].scrollIntoView(true)
