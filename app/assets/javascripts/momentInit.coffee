window.initMoment = ->
  moment.locale I18n.locale,
    months: I18nHelper.monthNames
    monthsShort: I18nHelper.abbrMonthNames
    weekdays: I18n.t('date.day_names')
    weekdaysShort: I18n.t('date.abbr_day_names')
    weekdaysMin: I18n.t('date.abbr_day_names')
    week:
      dow: 1
      doy: 4
