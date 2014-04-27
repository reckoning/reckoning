#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require spin.js/spin
#= require ladda/js/ladda
#= require noty/js/noty/packaged/jquery.noty.packaged.min
#= require sifter/sifter
#= require microplugin/src/microplugin
#= require selectize/dist/js/selectize
#= require bootstrap
#= require dynamic_fields_for
#= require i18next
#= require i18n/translations
#= require i18n_init
#= require helper
#= require moment/moment
#= require moment_init
#= require d3/d3
#= require nvd3/nv.d3
#= require app
#= require_tree ./app
#
#= require turbolinks

$(document).on 'show.bs.collapse', '.navbar-collapse', (ev) ->
  $('.navbar-collapse.in').not(@).collapse('hide')

$(document).on 'i18n'

$ ->
  $('.btn.btn-loading').click ->
    $(@).button('loading')

  $('#blueimp-gallery').data('useBootstrapModal', false)

