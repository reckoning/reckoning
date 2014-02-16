window.App ?= {}

$(document).on 'click', 'a.disabled', (evt) ->
  false

$ ->
  if success = $('body').attr('data-success')
    displaySuccess success

  if info = $('body').attr('data-info')
    displayAlert info

  if error = $('body').attr('data-error')
    displayError error

  if warning = $('body').attr('data-warning')
    displayWarning warning

  $('select.js-selectize').selectize
    plugins: ['remove_button']
    dataAttr: 'data-data'
