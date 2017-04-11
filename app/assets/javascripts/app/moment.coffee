class App.Moment
  init: ->
    moment.updateLocale I18n.locale,
      week:
        dow: 1
        doy: 4

    moment.locale(I18n.locale)
