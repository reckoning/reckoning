window.initMoment = ->
  month_names = I18n.t('date.month_names')
  abbr_month_names = I18n.t('date.abbr_month_names')
  month_names.shift()
  abbr_month_names.shift()
  moment.locale I18n.locale,
    months: month_names
    monthsShort: abbr_month_names
    weekdays: I18n.t('date.day_names')
    weekdaysShort: I18n.t('date.abbr_day_names')
    weekdaysMin: I18n.t('date.abbr_day_names')
    week:
      dow: 1
      doy: 4
