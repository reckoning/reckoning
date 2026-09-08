# Highcharts 4.2.5

The same vendored build the server-rendered app loads through Sprockets from
`app/assets/javascripts/vendor/highcharts/`, copied here so Vite can bundle it
for the SPA. Duplicated rather than shared because Vite's dev server only
serves files below `app/frontend`, and Sprockets' load path does not reach
into it — the Sprockets copy goes away with `app/assets` in the last phase of
the migration.

Both files are UMD and register `window.Highcharts`; `lib/highcharts.ts` wraps
that global so the cast lives in one place.
