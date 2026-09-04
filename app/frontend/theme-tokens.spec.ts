import { describe, expect, it } from "vitest"
import { readdirSync, readFileSync } from "node:fs"
import { join } from "node:path"

// Colours belong in spa.css's `@theme` block. The dark mode and redesign
// planned for phase C (docs/vue-spa-migration-plan.md) are meant to be a swap
// in that one block, which only holds while no page carries a colour of its
// own — and the SPA had accumulated 46 such colours before they were pulled
// into tokens. Six more domains get ported in B3–B8, so the habit is checked
// here rather than left to review.
// vitest runs from the repo root — `include` in vitest.config.mts is
// root-relative too.
const root = join(process.cwd(), "app/frontend")

const sources = readdirSync(root, {recursive: true, encoding: "utf8"})
  .filter((file) => file.endsWith(".vue") || (file.endsWith(".ts") && !file.endsWith(".spec.ts")))
  .map((file) => ({file, body: readFileSync(join(root, file), "utf8")}))

const hits = (pattern: RegExp, scope = (file: string) => true) =>
  sources
    .filter(({file}) => scope(file))
    .flatMap(({file, body}) => [...body.matchAll(pattern)].map((match) => `${file}: ${match[0]}`))

const PALETTE =
  "slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose"

describe("colour tokens", () => {
  it("reads the frontend sources", () => {
    expect(sources.length).toBeGreaterThan(20)
  })

  it("writes no raw colour into a utility class", () => {
    expect(hits(/-\[#[0-9a-fA-F]{3,8}\]/g)).toEqual([])
  })

  // `text-white` stays allowed: it is a foreground paired with its own fill
  // (the brand and warning buttons), not a surface, and it survives a dark
  // theme unchanged. A surface has to come from a token.
  it("takes surfaces from tokens rather than white or black", () => {
    expect(hits(/\b(?:bg|border|from|via|to)-(?:white|black)\b/g)).toEqual([])
  })

  // Scoped to pages: `ToastHost.vue` still paints its success/info/error
  // variants from the Tailwind palette. Those need semantic tokens whose
  // values are a design decision, so they are the redesign's to make, not a
  // mechanical rename's.
  it("keeps the Tailwind palette out of the pages", () => {
    expect(hits(new RegExp(`\\b(?:bg|text|border)-(?:${PALETTE})-[0-9]{2,3}\\b`, "g"), (file) =>
      file.startsWith("pages/")
    )).toEqual([])
  })
})
