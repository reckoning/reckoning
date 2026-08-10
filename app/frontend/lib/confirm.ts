// Awaitable confirm for the Vue islands.
//
// The legacy Sprockets bundle ships `window.notyConfirm` (see
// `app/assets/javascripts/helpers/noty.coffee`) — a noty dialog that
// takes ok/cancel callbacks and returns straight away. Islands render
// inside that layout, so prefer it for a consistent look and wrap it
// in a promise; outside it (tests, a future standalone page) fall back
// to the blocking native dialog.

type NotyConfirm = (message: string, ok: () => void, cancel: () => void) => unknown

interface ConfirmGlobals {
  notyConfirm?: NotyConfirm
}

export function confirmDialog(message: string): Promise<boolean> {
  const notyConfirm = (window as unknown as ConfirmGlobals).notyConfirm
  if (typeof notyConfirm !== "function") return Promise.resolve(window.confirm(message))

  return new Promise((resolve) => {
    let settled = false
    const settle = (answer: boolean) => {
      if (settled) return
      settled = true
      resolve(answer)
    }
    notyConfirm(
      message,
      () => settle(true),
      () => settle(false),
    )
  })
}
