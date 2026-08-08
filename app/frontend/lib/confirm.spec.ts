import {describe, it, expect, afterEach, vi} from "vitest"
import {confirmDialog} from "./confirm"

interface ConfirmGlobals {
  notyConfirm?: unknown
}

const globals = window as unknown as ConfirmGlobals

afterEach(() => {
  delete globals.notyConfirm
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
})

describe("confirmDialog", () => {
  it("stays pending until the noty dialog is answered", async () => {
    let ok: () => void = () => {}
    globals.notyConfirm = vi.fn((_message: string, okCallback: () => void) => {
      ok = okCallback
    })

    const settled = vi.fn()
    const answer = confirmDialog("Delete?").then(settled)

    await Promise.resolve()
    expect(settled).not.toHaveBeenCalled()

    ok()
    await expect(answer).resolves.toBe(undefined)
    expect(settled).toHaveBeenCalledWith(true)
  })

  it("resolves false when the dialog is cancelled", async () => {
    globals.notyConfirm = (_message: string, _ok: () => void, cancel: () => void) => cancel()

    await expect(confirmDialog("Delete?")).resolves.toBe(false)
  })

  it("ignores a second answer from the same dialog", async () => {
    let ok: () => void = () => {}
    let cancel: () => void = () => {}
    globals.notyConfirm = (_m: string, okCallback: () => void, cancelCallback: () => void) => {
      ok = okCallback
      cancel = cancelCallback
    }

    const answer = confirmDialog("Delete?")
    ok()
    cancel()

    await expect(answer).resolves.toBe(true)
  })

  it("falls back to the native dialog when noty is absent", async () => {
    // happy-dom has no window.confirm of its own to spy on.
    const native = vi.fn(() => false)
    vi.stubGlobal("confirm", native)

    await expect(confirmDialog("Delete?")).resolves.toBe(false)
    expect(native).toHaveBeenCalledWith("Delete?")
  })
})
