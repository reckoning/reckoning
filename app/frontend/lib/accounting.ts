// Ports app/assets/javascripts/app/accounting.coffee from the
// legacy Sprockets bundle. `accounting.js` itself moves with it
// (via npm) so the Sprockets `//= require accounting.js/accounting`
// + the bower component are no longer needed.
//
// `window.accounting` stays the public API because chart.coffee
// (still in Sprockets) calls `accounting.formatMoney(...)` as a
// global. Once chart.coffee ports to TS, the global goes away.

// accounting@0.4.1 ships UMD without TS types. Looser typing is
// fine — this surface retires with chart.coffee in a later step.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
import accounting from "accounting"

interface AccountingSettings {
  currency: {
    symbol: string
    format: string
    decimal: string
    thousand: string
    precision: number
  }
  number: {
    precision: number
    thousand: string
    decimal: string
  }
}

interface I18nGlobal {
  t: (key: string) => string | number
}

export function configureAccounting(I18n: I18nGlobal): void {
  const settings: AccountingSettings = {
    currency: {
      symbol: String(I18n.t("number.currency.format.unit")),
      format: String(I18n.t("number.currency.format.accounting_format")),
      decimal: String(I18n.t("number.currency.format.separator")),
      thousand: String(I18n.t("number.currency.format.delimiter")),
      precision: Number(I18n.t("number.currency.format.precision")),
    },
    number: {
      precision: Number(I18n.t("number.format.precision")),
      thousand: String(I18n.t("number.currency.format.delimiter")),
      decimal: String(I18n.t("number.currency.format.separator")),
    },
  }
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ;(accounting as any).settings = settings
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function installAccountingGlobal(): typeof accounting {
  ;(window as unknown as { accounting: typeof accounting }).accounting = accounting
  return accounting
}
