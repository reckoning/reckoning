#= require pickadate/lib/picker
#= require pickadate/lib/picker.date
#= require pickadate/lib/picker.time

window.Datepicker =
  options: ->
    {
      monthsFull: I18n.t('date.month_names').filter((month) -> month)
      monthsShort: I18n.t('date.abbr_month_names').filter((month) -> month)
      weekdaysFull: I18n.t('date.day_names')
      weekdaysShort: I18n.t('date.abbr_day_names')
      labelMonthNext: I18n.t('labels.datepicker.next_month')
      labelMonthPrev: I18n.t('labels.datepicker.previous_month')
      labelMonthSelect: I18n.t('labels.datepicker.months')
      labelYearSelect: I18n.t('labels.datepicker.years')
      format: I18n.t('datepicker.formats.default')
      formatSubmit: I18n.t('datepicker.formats.submit')
      selectYears: true
      firstDay: I18n.t('date.first_day_of_week')
      today: I18n.t('actions.today')
      clear: ' '
      close: ' '
    }

  init: ($element, withoutInput) ->
    withoutInput ?= false
    options = @options()

    if withoutInput
      options.clear = false
      options.container = "body"
      options.containerHidden = "body"
    else
      options.hiddenName = true

    @setup $element, options

  setup: ($element, options) ->
    $pickerElement = $element.pickadate options

    picker = $pickerElement.pickadate('picker')

    $element.parent().find('.input-group-btn .btn').on 'click', (event) ->
      event.stopPropagation()
      event.preventDefault()
      picker.open()

    picker

window.Timepicker =
  options: ->
    {
      format: I18n.t('timepicker.formats.default')
      clear: ' '
      interval: 5
    }

  init: ($element, withoutInput) ->
    withoutInput ?= false
    options = @options()

    if withoutInput
      options.clear = false
      options.container = "body"
      options.containerHidden = "body"

    @setup $element, options

  setup: ($element, options) ->
    $pickerElement = $element.pickatime options

    picker = $pickerElement.pickatime('picker')

    $element.parent().find('.input-group-btn .btn').on 'click', (event) ->
      event.stopPropagation()
      event.preventDefault()
      picker.open()

    picker

# Datepicker init is now driven by the Stimulus
# `datepicker_controller` (app/frontend/controllers/) which connects
# on element insertion — including Turbo Frame swaps. The
# `.timepicker` global init never had a callsite outside AngularJS
# (which calls `Timepicker.init` directly from
# angular/base/directives/timepicker.coffee), so it's dropped too.
#
# `window.Datepicker` / `window.Timepicker` themselves stay below
# until Phase 7 retires the AngularJS directives that consume them.
