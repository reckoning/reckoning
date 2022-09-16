window.App.Offer ?= {}

window.App.Offer.projectRate = 0
window.App.Offer.oldProjectRate = 0

window.laddaButton ?= {}

window.App.Offer.showPreview = ->
  $('#offer #preview-info').addClass('hide')
  $("#offer .pdf-viewer").parent().removeClass('hide')

window.App.Offer.updateValues = (ev, $fields) ->
  $fields.each (i, field) ->
    App.Offer.updateValue(ev, $(field))

window.App.Offer.updateValue = (ev, $field) ->
  $field ||= $(ev.target).closest('.fields')
  $valueInput = $field.find('input.offer-position-value')
  $valueSpan = $field.find('span.offer-position-value')
  $rateInput = $field.find('input.offer-position-rate')
  hours = $field.find('.offer-position-hours').val()
  rate = $rateInput.val()
  if hours.length
    if !rate.length || rate is App.Offer.oldProjectRate
      rate = App.Offer.projectRate
      $rateInput.val(rate)
    if rate.length
      value = hours * rate
      $valueInput.val(value)
      $valueSpan.text(value)

window.App.Offer.updateRate = (ev) ->
  $target = $(ev.target)
  projectId = $target.val()
  if projectId.length
    projectSelect = $target[0].selectize
    App.Offer.projectRate = projectSelect.options[projectId].rate
    App.Offer.updateValues ev, $('form#offer-form').find('.fields')
    App.Offer.oldProjectRate = App.Offer.projectRate

$(document).on 'change', ".offer-position-hours", App.Offer.updateValue
$(document).on 'change', ".offer-position-rate", App.Offer.updateValue
$(document).on 'change', "#offer_project_id", App.Offer.updateRate

document.addEventListener "turbolinks:load", ->
  if $('#offer-form').length
    button = document.querySelector('.ladda-button')
    if button
      window.laddaButton = Ladda.create(button)

    projectSelect = $('#offer_project_id')[0].selectize
    projectId = $('#offer_project_id').val()
    if projectId.length
      App.Offer.projectRate = projectSelect.options[projectId].rate

    $('#offer_project_id').data('pre', App.Offer.projectRate)
