import { createApp, type Component } from "vue"

// Generic Vue island mounter. Pages opt in by rendering a
// `<div data-island="<name>" data-island-props='{"…":"…"}'></div>`
// element. This module looks up the matching component in the
// passed registry and mounts a Vue app at the element.
//
// Why an islands pattern rather than one big SPA: the rest of the
// reckoning UI is server-rendered ERB + Turbo Frames. We only
// reach for Vue on the two interaction-heavy screens (timesheet,
// timers calendar) that justify its complexity. The islands
// architecture lets the two coexist without colliding.
//
// `data-island-props` is parsed as JSON. Missing or invalid JSON
// is ignored — the component runs with whatever defaults it has.

type IslandRegistry = Record<string, Component>

export function mountIslands(registry: IslandRegistry): void {
  const mounts = document.querySelectorAll<HTMLElement>("[data-island]")
  for (const mount of mounts) {
    const name = mount.dataset.island
    if (!name) continue
    const component = registry[name]
    if (!component) {
      // Unknown island name — fail loud in dev so a typo is
      // caught early; silent in prod so a stale view doesn't
      // crash the page.
      if (import.meta.env.DEV) {
        console.error(`[islands] No registered component for data-island="${name}"`)
      }
      continue
    }

    let props: Record<string, unknown> = {}
    const propsAttr = mount.dataset.islandProps
    if (propsAttr) {
      try {
        props = JSON.parse(propsAttr)
      } catch (e) {
        if (import.meta.env.DEV) {
          console.error(`[islands] data-island-props for "${name}" is not valid JSON:`, e)
        }
      }
    }

    createApp(component, props).mount(mount)
  }
}
