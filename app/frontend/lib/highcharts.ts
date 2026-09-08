export interface HighchartsPoint {
  y: number
  color: string
  category: {short: string; long: string; date: string}
  series: {name: string}
}

export interface HighchartsChart {
  destroy(): void
  container: HTMLElement
}

interface HighchartsGlobal {
  Chart: new (options: object) => HighchartsChart
  setOptions(options: object): void
}

// The vendored build is UMD: in the browser it assigns `window.Highcharts`,
// while under Vitest's transform `module` exists, so it exports itself
// instead. Either way the global has to be in place before the no-data
// plugin is evaluated, which reads it as a free variable — hence the awaited
// imports rather than two static ones.
const bundle = await import("@/vendor/highcharts/highcharts.js")
const container = globalThis as unknown as {Highcharts?: HighchartsGlobal}

container.Highcharts ??= bundle.default as HighchartsGlobal | undefined

await import("@/vendor/highcharts/no-data-to-display.js")

export const Highcharts = container.Highcharts as HighchartsGlobal
