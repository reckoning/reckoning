window.App.Invoice ?= {}

window.App.Invoice.pdfInterval = false
window.App.Invoice.projectRate = 0
window.App.Invoice.oldProjectRate = 0

window.laddaButton ?= {}

window.App.Invoice.generate = ($element) ->
  laddaButton.start() if laddaButton
  $('.save-invoice').addClass('disabled')
  $('.save-timesheet').addClass('disabled')
  $element.find('.generate').addClass('hide')
  $element.find('.regenerate').removeClass('hide')
  $.ajax
    url: $element.attr('data-action')
    type: 'PUT'
    dataType: 'json'
    success: ->
      displayInfo I18n.t("messages.invoice.pdf_generating")
      App.Invoice.pdfInterval = setInterval App.Invoice.checkPdfStatus, 1000

window.App.Invoice.checkPdfStatus = ->
  id = $('#invoice').attr('data-id')
  $.ajax
    url: Routes.check_pdf_invoice_path(id)
    dataType: 'json'
    success: (data) ->
      return unless data
      laddaButton.stop() if laddaButton
      $("#invoice-preview .pdf-viewer").data('pdfPath', data.invoice)
      $('.save-invoice').removeClass('disabled')
      if data.timesheet
        $('#timesheet-preview .pdf-viewer').data('pdfPath', data.timesheet)
        $('.save-timesheet').removeClass('disabled')
      clearInterval App.Invoice.pdfInterval
      displaySuccess I18n.t("messages.invoice.pdf_generated")
      PdfViewer.load()
      App.Invoice.showPreview()

window.App.Invoice.showPreview = ->
  $('#preview-info').addClass('hide')
  $(".pdf-viewer").parent().removeClass('hide')

window.App.Invoice.updateValues = (ev, $fields) ->
  $fields.each (i, field) ->
    App.Invoice.updateValue(ev, $(field))

window.App.Invoice.updateValue = (ev, $field) ->
  $field ||= $(ev.target).closest('.fields')
  $valueInput = $field.find('input.invoice-position-value')
  $valueSpan = $field.find('span.invoice-position-value')
  $rateInput = $field.find('input.invoice-position-rate')
  hours = $field.find('.invoice-position-hours').val()
  rate = $rateInput.val()
  if hours.length
    if !rate.length || rate is App.Invoice.oldProjectRate
      rate = App.Invoice.projectRate
      $rateInput.val(rate)
    if rate.length
      value = hours * rate
      $valueInput.val(value)
      $valueSpan.text(value)

window.App.Invoice.updateRate = (ev) ->
  $target = $(ev.target)
  project_id = $target.val()
  if project_id.length
    project_select = $target[0].selectize
    App.Invoice.projectRate = project_select.options[project_id].rate
    App.Invoice.updateValues ev, $('form#invoice-form').find('.fields')
    App.Invoice.oldProjectRate = App.Invoice.projectRate

window.App.Invoice.loadPositions = ($element) ->
  laddaButton.start() if laddaButton
  project_id = $('#invoice_project_id').val()
  unless project_id.length
    displayAlert I18n.t("messages.invoice.load_positions.missing")
    laddaButton.stop() if laddaButton
    return

  xhr.abort() if xhr
  xhr = $.ajax
    url: Routes.uninvoiced_project_tasks_path(project_id)
    dataType: 'json'
    context: $('#add-positions-modal')
    success: (result) ->
      $(@).find('#add-positions').html(result.body)
      $(@).modal('show')
    error: ->
      displayError I18n.t("messages.error")
    complete: ->
      laddaButton.stop() if laddaButton

window.App.Invoice.addPositions = ($form) ->
  fields = $form.serializeArray()
  $positions = $('#positions')
  $.each fields, (i, field) ->
  fields = $form.serializeArray()
  $positions = $('#positions')
  $.each fields, (i, field) ->
    data = JSON.parse(field.value)

    time = new Date().getTime()
    regexp = new RegExp($positions.data('id'), 'g')
    $fields = $($positions.data('fields').replace(regexp, time))
    $positions.append($fields)

    $fields.find('input[name*=description]').val(data.name)
    $fields.find('input[name*=hours]').val(data.value.toFixed(2))
    $fields.find('span.invoice-position-hours').text(data.value.toFixed(2))
    $fields.find('select[name*=timer_ids]').val(data.timer_ids)
    App.Invoice.updateValue({}, $fields, 0)

  $('#add-positions-modal').modal('hide')

$(document).on 'change', ".invoice-position-hours", App.Invoice.updateValue
$(document).on 'change', ".invoice-position-rate", App.Invoice.updateValue
$(document).on 'change', "#invoice_project_id", App.Invoice.updateRate

$ ->
  if $('#invoice').length
    button = document.querySelector('.ladda-button')
    if button
      window.laddaButton = Ladda.create(button)

    if $('.generate-invoice').hasClass('generating')
      laddaButton.start() if laddaButton
      $('.generate-invoice').removeClass('generating')
      App.Invoice.pdfInterval = setInterval App.Invoice.checkPdfStatus, 1000

  if $('#invoice-form').length
    project_select = $('#invoice_project_id')[0].selectize
    project_id = $('#invoice_project_id').val()
    if project_id.length
      App.Invoice.projectRate = project_select.options[project_id].rate

    $('#invoice_project_id').data('pre', App.Invoice.projectRate)

    button = document.querySelector('.ladda-button')
    if button
      window.laddaButton = Ladda.create(button)
