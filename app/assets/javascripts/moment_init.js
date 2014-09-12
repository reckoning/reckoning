window.initMoment = function() {
  moment.locale(I18n.locale, {
    months: I18n.t('date.dp_month_names'),
    monthsShort: I18n.t('date.dp_abbr_month_names'),
    weekdays: I18n.t('date.day_names'),
    weekdaysShort: I18n.t('date.abbr_day_names'),
    weekdaysMin: I18n.t('date.abbr_day_names'),
    week: {
      dow: 1,
      doy: 4
    }
  });
};
