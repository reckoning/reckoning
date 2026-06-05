import { Controller } from "@hotwired/stimulus"

// Variant of the selectize controller that also lets the user
// create a new customer inline via the v1 customers API. Used in
// projects/_form for the customer_id picker. Behavior is a direct
// port of the legacy `App.Selectize` class init for
// `select.js-customer-selectize`.
//
// `ApiBasePath`, `ApiHeaders`, and `selectizeCreateTemplate` are
// set on `window` by app/views/layouts/_js_defaults.html.erb and
// app/assets/javascripts/helpers/selectize.coffee respectively.
//
// Attach via `data-controller="customer-selectize"`.

interface SelectizeInstance {
  destroy?: () => void
  addOption?: (data: { value: string; text: string }) => void
  addItem?: (value: string) => void
}

interface AppGlobals {
  $?: unknown
  ApiBasePath?: string
  ApiHeaders?: HeadersInit
  selectizeCreateTemplate?: (data: { input: string }, escape: (s: string) => string) => string
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const win = window as unknown as AppGlobals
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const jq: any = win.$ ?? null

export default class extends Controller {
  private selectize: SelectizeInstance | null = null

  connect() {
    if (!jq) return

    const $el = jq(this.element).selectize({
      render: { option_create: win.selectizeCreateTemplate },
      create: (input: string, callback: (data?: { value: string; text: string }) => void) => {
        fetch(`${win.ApiBasePath ?? ""}/api/v1/customers`, {
          headers: win.ApiHeaders,
          method: "POST",
          body: JSON.stringify({name: input}),
        })
          .then((r) => r.json())
          .then((result: { id: string; name: string }) => {
            const data = {value: result.id, text: result.name}
            this.selectize?.addOption?.(data)
            this.selectize?.addItem?.(result.id)
            callback(data)
          })
          .catch(() => callback())
      },
    })

    this.selectize = ($el[0]?.selectize as SelectizeInstance) ?? null
  }

  disconnect() {
    this.selectize?.destroy?.()
    this.selectize = null
  }
}
