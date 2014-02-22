$ ->
  moment.lang locale,
    months: i18n.t('date.dp_month_names').split('\n')
    monthsShort: i18n.t('date.dp_abbr_month_names').split('\n')
    weekdays: i18n.t('date.day_names').split('\n')
    weekdaysShort: i18n.t('date.abbr_day_names').split('\n')
    weekdaysMin: i18n.t('date.abbr_day_names').split('\n')
    week:
      dow: 1
      doy: 4
