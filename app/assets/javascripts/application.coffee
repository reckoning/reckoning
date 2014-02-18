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
#= require app
#= require_tree ./app
#
#= require turbolinks

window.setMinHeight = ->
  offset = $('footer#main-footer').outerHeight() + $('nav#main-nav').outerHeight() - 50
  $('body > .container').css('min-height', $('body').height() - offset)

$(document).on 'click', 'a.disabled', (evt) ->
  false

$(document).on 'show.bs.collapse', '.navbar-collapse', (ev) ->
  $('.navbar-collapse.in').not(@).collapse('hide')

$(window).on 'orientationchange', setMinHeight
$(window).on 'resize', setMinHeight

$ ->
  $('.btn.btn-loading').click ->
    $(@).button('loading')

  $('#blueimp-gallery').data('useBootstrapModal', false)

  setMinHeight()
