window.I18nHelper =
  monthNames: []
  abbrMonthNames: []
  initialized: false
  init: ->
    unless @initialized
      names = I18n.t('date.month_names')
      names.shift()
      @monthNames = names

      names = I18n.t('date.abbr_month_names')
      names.shift()
      @abbrMonthNames = names

      @initialized = true

document.addEventListener "turbolinks:load", ->
  I18nHelper.init()
