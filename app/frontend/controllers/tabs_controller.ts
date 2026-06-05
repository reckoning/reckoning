import { Controller } from "@hotwired/stimulus"

// Replaces app/assets/javascripts/tabs.js. Attach to the tab nav
// element (e.g. `<ul class="nav nav-tabs">` or `nav-tabs-vertical`)
// with `data-controller="tabs"`. Bootstrap 3's tab plugin still owns
// the show/hide; this controller syncs the URL hash + the form's
// hidden hash field, and re-opens the right tab on initial load and
// on back/forward navigation.
//
// Behaviorally equivalent to the legacy tabs.js — same selectors,
// same form-action mutation, same pushState pattern.
//
// jQuery is still on the page (Sprockets bundle) and Bootstrap 3's
// tab plugin dispatches `shown.bs.tab` through jQuery, so we read
// through the global `$`. Typed loose on purpose — this controller
// gets retired in Phase 9 when jQuery/Bootstrap 3 leave.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const jq: any = (window as unknown as { $: unknown }).$ ?? null

export default class extends Controller {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private boundOnShow = (e: any) => this.onTabShown(e)
  private boundOpenByHash = () => this.openByHash()

  connect() {
    if (!jq) return
    // Bootstrap dispatches `shown.bs.tab` via jQuery delegation on
    // `a[data-toggle="tab"]`. Scope the listener to this controller's
    // root element so two parallel tab navs on a page don't fight.
    jq(this.element).on("shown.bs.tab", "a[data-toggle=\"tab\"]", this.boundOnShow)
    this.openByHash()
    window.addEventListener("popstate", this.boundOpenByHash)
  }

  disconnect() {
    if (!jq) return
    jq(this.element).off("shown.bs.tab", "a[data-toggle=\"tab\"]", this.boundOnShow)
    window.removeEventListener("popstate", this.boundOpenByHash)
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private onTabShown(e: any) {
    const targetHash = (e.target as HTMLAnchorElement | undefined)?.hash
    if (!targetHash) return

    // Sync the form's hidden hash field + action URL so a subsequent
    // submit lands the user back on the same tab. Matches the legacy
    // tabs.js behavior — same selectors.
    const $form = jq("form")
    if (!$form.length) return

    $form.find("input[name=hash]").val(targetHash)
    const action = ($form.attr("action") || "").split("#")[0]
    $form.attr("action", action + targetHash)

    history.pushState({}, "", targetHash)
  }

  private openByHash() {
    const links = jq(this.element).find("a[data-toggle=\"tab\"]")
    if (!links.length) return

    const hash = window.location.hash
    // Skip Angular-style hash routes (`#/day/...`) — same guard as
    // the legacy code.
    if (hash && hash.length > 0 && !/^#\//.test(hash)) {
      const targetLink = links.filter(`[href="${hash}"]`)
      if (targetLink.length) {
        targetLink.tab("show")
        return
      }
    }
    links.first().tab("show")
  }
}
