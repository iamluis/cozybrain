// Explicit scroll-position memory keyed by URL path. Belt-and-suspenders
// in case Turbo Drive's built-in restoration or Safari's BFCache don't
// kick in (e.g. when our `stale?` / `fresh_when` responses include
// Cache-Control: must-revalidate, which some browsers treat as "exempt
// from BFCache").
//
// Attached to <body data-controller="scroll-memory">. Listens for two
// Turbo events globally:
//   · turbo:before-visit — stash current scrollY under current path
//   · turbo:load         — if we have a saved scrollY for this path,
//                          restore it (only when returning to the path,
//                          not on advance to a brand-new page).
//
// Storage: sessionStorage, keyed under "brain.scroll". Map of
// { "<pathname>": <scrollY> }. Resets when the tab closes.
import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "brain.scroll"

export default class extends Controller {
  connect() {
    this._save    = this.save.bind(this)
    this._restore = this.restore.bind(this)
    document.addEventListener("turbo:before-visit", this._save)
    document.addEventListener("turbo:load",        this._restore)
    // Restore once on initial connect too, in case turbo:load already fired.
    this.restore()
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this._save)
    document.removeEventListener("turbo:load",        this._restore)
  }

  save() {
    const map = this.read()
    map[location.pathname] = window.scrollY
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(map))
  }

  restore() {
    const map = this.read()
    const y   = map[location.pathname]
    if (y == null) return
    requestAnimationFrame(() => window.scrollTo(0, y))
  }

  read() {
    try {
      return JSON.parse(sessionStorage.getItem(STORAGE_KEY) || "{}")
    } catch {
      return {}
    }
  }
}
