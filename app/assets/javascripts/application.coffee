#= require jquery
#= require jquery_ujs
#= require js-routes
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
#= require i18n-helper
#= require moment/moment
#= require moment-init
#= require twix/bin/twix
#= require accounting/accounting
#= require accounting-init
#= require nprogress
#= require fastclick
#= require pdfjs-dist/build/pdf
#= require d3
#= require nvd3
#= require vendor/highcharts/highcharts
#= require vendor/highcharts/no-data-to-display
#= require pdf-viewer
#= require helper
#= require_tree ./helpers
#= require tabs
#= require app
#= require_tree ./app
#= require angular-init
#= require base
#= require blank
#= require timesheet

window.domain = (location.host.match(/([^.]+)\.\w{2,3}(?:\.\w{2})?$/) || [])[0]
window.ApiBasePath = "//api.#{domain}"

$(document).on 'show.bs.collapse', '.navbar-collapse', ->
  $('.navbar-collapse.in').not(this).collapse('hide')

$ ->
  FastClick.attach(document.body)

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
