window.monthNames = []
window.abbrMonthNames = []

window.initMoment = ->
  names = I18n.t('date.month_names')
  names.shift()
  window.monthNames = names

  names = I18n.t('date.abbr_month_names')
  names.shift()
  window.abbrMonthNames = names

  moment.locale I18n.locale,
    months: monthNames
    monthsShort: abbrMonthNames
    weekdays: I18n.t('date.day_names')
    weekdaysShort: I18n.t('date.abbr_day_names')
    weekdaysMin: I18n.t('date.abbr_day_names')
    week:
      dow: 1
      doy: 4
