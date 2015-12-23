window.initAccounting = ->
  accounting.settings =
    currency:
      symbol: I18n.t('number.currency.format.unit')
      format: I18n.t('number.currency.format.accounting_format')
      decimal: I18n.t('number.currency.format.separator')
      thousand: I18n.t('number.currency.format.delimiter')
      precision: I18n.t('number.currency.format.precision')
    number:
      precision: I18n.t('number.format.precision')
      thousand: I18n.t('number.currency.format.delimiter')
      decimal: I18n.t('number.currency.format.separator')
