#= require pickadate/lib/picker
#= require pickadate/lib/picker.date

window.Datepicker =
  init: ($element, withoutInput) ->
    I18nHelper.init()

    withoutInput ?= false
    options =
      monthsFull: I18nHelper.monthNames
      monthsShort: I18nHelper.abbrMonthNames
      weekdaysFull: I18n.t('date.day_names')
      weekdaysShort: I18n.t('date.abbr_day_names')
      labelMonthNext: I18n.t('labels.datepicker.next_month')
      labelMonthPrev: I18n.t('labels.datepicker.previous_month')
      labelMonthSelect: I18n.t('labels.datepicker.months')
      labelYearSelect: I18n.t('labels.datepicker.years')
      format: I18n.t('date.formats.datepicker')
      formatSubmit: I18n.t('date.formats.datepicker_submit')
      selectYears: true
      firstDay: I18n.t('date.first_day_of_week')
      today: I18n.t('actions.today')
      clear: ' '
      close: ' '

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

$ ->
  $('.datepicker').each ->
    Datepicker.init($(@).find('input'))
