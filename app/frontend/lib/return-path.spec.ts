import { describe, expect, it } from "vitest"
import { safeReturnPath } from "./return-path"

describe("safeReturnPath", () => {
  it("takes a path inside this app", () => {
    expect(safeReturnPath("/invoices")).toBe("/invoices")
    expect(safeReturnPath("/invoices?page=2")).toBe("/invoices?page=2")
  })

  it("refuses a url pointing at another host", () => {
    expect(safeReturnPath("//evil.example")).toBeUndefined()
    expect(safeReturnPath("/\\evil.example")).toBeUndefined()
    expect(safeReturnPath("https://evil.example")).toBeUndefined()
  })

  it("refuses anything that is not a path", () => {
    expect(safeReturnPath(undefined)).toBeUndefined()
    expect(safeReturnPath(["/invoices"])).toBeUndefined()
    expect(safeReturnPath("invoices")).toBeUndefined()
  })
})
