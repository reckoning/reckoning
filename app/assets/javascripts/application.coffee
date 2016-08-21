#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require js-routes
#= require action_cable
#= require spin.js/spin
#= require ladda/js/ladda
#= require noty
#= require sifter
#= require microplugin
#= require selectize
#= require bootstrap
#= require dynamic_fields_for
#= require i18n
#= require i18n/translations
#= require i18nHelper
#= require moment/moment
#= require momentInit
#= require twix/dist/twix
#= require accounting.js/accounting
#= require accountingInit
#= require nprogress
#= require underscore
#= require pdfjs-dist/build/pdf
#= require d3
#= require nvd3
#= require vendor/highcharts/highcharts
#= require vendor/highcharts/no-data-to-display
#= require pdfViewer
#= require refile
#= require helper
#= require_tree ./helpers
#= require tabs
#= require app
#= require cable
#= require_tree ./app
#= require angularInit
#= require base
#= require blank
#= require timesheet
#= require timersCalendar
#= require logbook
#= require geoLocation

$(document).on 'show.bs.collapse', '.navbar-collapse', ->
  $('.navbar-collapse.in').not(this).collapse('hide')

$(document).on "upload:start", "form", (e) ->
  $(@).find("[type=submit]").attr("disabled", true)

$(document).on "upload:complete", "form", (e) ->
  if !$(@).find("input.uploading").length
    $(@).find("[type=submit]").removeAttr("disabled")

document.addEventListener "turbolinks:load", ->
  $('.btn.btn-loading').click ->
    $(this).button('loading')

  if ("standalone" in window.navigator) && window.navigator.standalone
    noddy = remotes = false

    document.addEventListener 'click', (event) ->
      noddy = event.target

      while noddy.nodeName isnt "A" && noddy.nodeName isnt "HTML"
        noddy = noddy.parentNode

      if 'href' in noddy && noddy.href.indexOf('http') isnt -1 && (noddy.href.indexOf(document.location.host) isnt -1 || remotes)
        event.preventDefault()
        document.location.href = noddy.href
    , false
