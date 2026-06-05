// Replaces app/assets/javascripts/app/moment.coffee's App.Moment.init.
// `moment` itself stays a global from the Sprockets bundle
// (`//= require moment/moment`) — chart.coffee, timer.coffee, and
// AngularJS code all read `window.moment`. We just configure the
// locale + week settings once on Vite bundle parse, using the
// Sprockets-set `window.I18n`.

interface I18nGlobal {
  locale: string
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type MomentGlobal = any

export function configureMomentLocale(): void {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const moment: MomentGlobal = (window as any).moment
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const I18n: I18nGlobal | undefined = (window as any).I18n
  if (!moment || !I18n) return

  moment.updateLocale(I18n.locale, {
    week: {dow: 1, doy: 4},
  })
  moment.locale(I18n.locale)
}
