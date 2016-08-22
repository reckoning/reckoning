#= require pickadate/lib/picker
#= require pickadate/lib/picker.date

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

document.addEventListener "turbolinks:load", ->
  $('.datepicker').each ->
    Datepicker.init($(@).find('input'))
