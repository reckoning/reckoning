window.App.Invoice ?= {}

window.App.Invoice.projectRate = 0
window.App.Invoice.oldProjectRate = 0

window.laddaButton ?= {}

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
  projectUuid = $target.val()
  if projectUuid.length
    projectSelect = $target[0].selectize
    App.Invoice.projectRate = projectSelect.options[projectUuid].rate
    App.Invoice.updateValues ev, $('form#invoice-form').find('.fields')
    App.Invoice.oldProjectRate = App.Invoice.projectRate

window.App.Invoice.loadPositions = ($element) ->
  laddaButton.start() if laddaButton
  projectUuid = $('#invoice_project_uuid').val()
  unless projectUuid.length
    displayAlert I18n.t("messages.invoice.load_positions.missing")
    laddaButton.stop() if laddaButton
    return

  timerUuids = []
  $("#positions").find('select[name*=timer_ids]').each ->
    timerUuids = timerUuids.concat($(@).val()) if $(@).val()

  xhr.abort() if xhr
  xhr = $.ajax
    url: Routes.uninvoiced_timers_path(projectUuid: projectUuid, timerUuids: timerUuids)
    dataType: 'json'
    context: $('#add-positions-modal')
    success: (result) ->
      $(@).find('#add-positions').html(result.body)
      $(@).modal('show')
    error: ->
      displayError I18n.t("messages.error")
    complete: ->
      laddaButton.stop() if laddaButton

window.App.Invoice.selectAllTimers = (ev) ->
  $("#add-positions").find(".list-group-item").each ->
    toggleCheckbox($(@))

  $icon = $(ev.target).closest("button[data-select-all]").find("i")
  $icon.toggleClass("fa-check-square-o")
  $icon.toggleClass("fa-square-o")


window.App.Invoice.addPositions = ($form) ->
  $positions = $('#positions')
  timers = $form.serializeArray().map (field) =>
    JSON.parse(field.value)
  groupedTimers = _.groupBy timers, (timer) => timer.taskUuid

  _.values(groupedTimers).forEach (timers) =>
    time = new Date().getTime()
    regexp = new RegExp($positions.data('id'), 'g')
    $fields = $($positions.data('fields').replace(regexp, time))
    $positions.append($fields)

    sum = _.reduce timers, (memo, timer) =>
      memo + timer.value
    , 0.0
    timerUuids = timers.map (timer) => timer.uuid

    $fields.find('input[name*=description]').val(timers[0].name)
    $fields.find('input[name*=hours]').val(sum.toFixed(2))
    $fields.find('span.invoice-position-hours').text(sum.toFixed(2))
    $fields.find('select[name*=timer_ids]').val(timerUuids)
    App.Invoice.updateValue({}, $fields, 0)

  $('#add-positions-modal').modal('hide')

$(document).on 'change', ".invoice-position-hours", App.Invoice.updateValue
$(document).on 'change', ".invoice-position-rate", App.Invoice.updateValue
$(document).on 'change', "#invoice_project_uuid", App.Invoice.updateRate
$(document).on 'click', "#add-positions-modal button[data-select-all]", App.Invoice.selectAllTimers

$ ->
  if $('#invoice-form').length
    button = document.querySelector('.ladda-button')
    if button
      window.laddaButton = Ladda.create(button)

    projectSelect = $('#invoice_project_uuid')[0].selectize
    projectUuid = $('#invoice_project_uuid').val()
    if projectUuid.length
      App.Invoice.projectRate = projectSelect.options[projectUuid].rate

    $('#invoice_project_uuid').data('pre', App.Invoice.projectRate)
