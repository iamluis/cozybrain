// Manages add/remove of line item rows on an invoice draft form.
// No server round-trip on add — a template row is cloned client-side and
// inserted into the form. On Save, Rails' accepts_nested_attributes_for
// picks up the new rows. Remove on a persisted row marks _destroy=1; on
// a freshly-added (unsaved) row it just yanks the DOM node.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rows", "template"]

  addRow(event) {
    event.preventDefault()
    const uniqueIndex = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueIndex)
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
  }

  removeRow(event) {
    event.preventDefault()
    const row = event.target.closest(".invoice__line")
    if (!row) return
    const destroyInput = row.querySelector("input[name*='_destroy']")
    if (destroyInput) {
      destroyInput.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }
}
