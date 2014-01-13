window.App.Invoice ?= {}

window.App.Invoice.pdfInterval = false
window.App.Invoice.previewPageHeight = 1060
window.App.Invoice.previewPageMax = 1
window.App.Invoice.currentPreviewPage = 1
window.App.Invoice.projectRate = 0

window.laddaButton ?= {}

window.App.Invoice.generate = ($element) ->
  laddaButton.start() if laddaButton
  $('.save-invoice').addClass('disabled')
  $element.find('.generate').addClass('hide')
  $element.find('.regenerate').removeClass('hide')
  $.ajax
    url: $element.attr('data-action')
    type: 'PUT'
    dataType: "JSON"
    success: ->
      displayAlert "PDF wird generiert"
      App.Invoice.pdfInterval = setInterval App.Invoice.checkPdfStatus, 1000

window.App.Invoice.checkPdfStatus = ->
  id = $('#invoice').attr('data-id')
  $.ajax
    url: r(check_pdf_invoice_path, id)
    dataType: "JSON"
    success: (data) ->
      return if data
      laddaButton.stop() if laddaButton
      $('.save-invoice').removeClass('disabled')
      clearInterval App.Invoice.pdfInterval
      displaySuccess "PDF wurde erfolgreich erstellt."
      App.Invoice.reloadPreview()

window.App.Invoice.showPreview = ->
  $('#preview-info').addClass('hide')
  $("#preview-image").removeClass('hide')
  $(".preview-paginator").removeClass('hide')

window.App.Invoice.reloadPreview = ->
  $previewImage = $("#preview-image")

  App.Invoice.showPreview() if $previewImage.is(':hidden')

  previewImageSrc = "#{$previewImage.attr("src")}?timestamp=#{new Date().getTime()}"
  $previewImage.attr("src", previewImageSrc)

  App.Invoice.updatePagination()

window.App.Invoice.changePreviewPage = ($el) ->
  $previewImage = $("#preview-image")

  type = $el.data('type')
  if type == 'next'
    App.Invoice.currentPreviewPage += 1
    $previewImage.css('top', "-=#{App.Invoice.previewPageHeight}")

  else if type == 'prev'
    App.Invoice.currentPreviewPage -= 1
    $previewImage.css('top', "+=#{App.Invoice.previewPageHeight}")

  App.Invoice.updatePagination()

window.App.Invoice.initPagination = ->
  $previewPaginator = $('.preview-paginator')
  return if $previewPaginator.is(':hidden')

  App.Invoice.updatePagination()

  $previewPaginator.find('li a').each (i, el) ->
    $(el).click (ev) ->
      ev.preventDefault()
      return if $(@).parent().hasClass('disabled')
      App.Invoice.changePreviewPage($(@))

window.App.Invoice.updatePagination = ->
  $previewPaginator = $('.preview-paginator')

  App.Invoice.previewPageMax = Math.round($("#preview-image").height() / App.Invoice.previewPageHeight)

  $previewPaginator.addClass('hide') if App.Invoice.previewPageMax == 1

  $nextEl = $previewPaginator.find('li a[data-type="next"]')
  $prevEl = $previewPaginator.find('li a[data-type="prev"]')

  if App.Invoice.currentPreviewPage >= App.Invoice.previewPageMax
    $nextEl.parent().addClass('disabled')
  else
    $nextEl.parent().removeClass('disabled')
  if App.Invoice.currentPreviewPage <= 1
    $prevEl.parent().addClass('disabled')
  else
    $prevEl.parent().removeClass('disabled')

window.App.Invoice.updateValues = (ev, $fields, oldRate) ->
  $fields.each (i, field) ->
    App.Invoice.updateValue(ev, $(field), oldRate)

window.App.Invoice.updateValue = (ev, $field, oldRate) ->
  $field ||= $(ev.target).closest('.fields')
  $valueInput = $field.find('.invoice-position-value')
  $rateInput = $field.find('.invoice-position-rate')
  hours = $field.find('.invoice-position-hours').val()
  rate = $rateInput.val()
  if hours.length
    if !rate.length || rate is oldRate
      rate = App.Invoice.projectRate
      $rateInput.val(rate)
    if rate.length
      value = hours * rate
      $valueInput.val(value)


window.App.Invoice.updateRate = (ev) ->
  $select = $(ev.target)
  App.Invoice.projectRate = $select.find('option:selected').data('rate')
  App.Invoice.updateValues ev, $('form#invoice-form').find('.fields'), $select.data('pre')
  $select.data('pre', App.Invoice.projectRate)

$(document).on 'change', ".invoice-position-hours", App.Invoice.updateValue
$(document).on 'change', ".invoice-position-rate", App.Invoice.updateValue
$(document).on 'change', "#invoice_project_id", App.Invoice.updateRate

$ ->
  if $('#invoice').length
    $("#preview-image").load ->
      App.Invoice.initPagination()

    button = document.querySelector('.ladda-button')
    if button
      window.laddaButton = Ladda.create(button)

    if $('.generate-invoice').hasClass('generating')
      laddaButton.start() if laddaButton
      $('.generate-invoice').removeClass('generating')
      App.Invoice.pdfInterval = setInterval App.Invoice.checkPdfStatus, 1000

    $(document).on 'page:load', ->
      App.Invoice.currentPreviewPage = 1
      App.Invoice.updatePagination()

  if $('#invoice-form').length
    App.Invoice.projectRate = $('#invoice_project_id').find('option:selected').data('rate')

    $('#invoice_project_id').data('pre', App.Invoice.projectRate)


