// Manages the editable invoice form:
//   · add/remove line item rows client-side (no server round-trip)
//   · recompute the running total live as quantity/rate inputs change
//   · auto-submit the form on blur or input change, debounced ~600ms
//
// On submit Turbo handles the request; the server response re-renders the
// form. Rails' accepts_nested_attributes_for + _destroy flag handles the
// persistence side.
import { Controller } from "@hotwired/stimulus"

const AUTOSAVE_DEBOUNCE_MS = 600

export default class extends Controller {
  static targets = ["rows", "template", "total", "savedPill"]

  connect() {
    this._timer = null
    this.recomputeTotal()
  }

  addRow(event) {
    event.preventDefault()
    const uniqueIndex = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueIndex)
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
    this.recomputeTotal()
    this.scheduleSubmit()
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
    this.recomputeTotal()
    this.scheduleSubmit()
  }

  // Wired to `input` on every editable field in the form.
  fieldChanged() {
    this.recomputeTotal()
    this.scheduleSubmit()
  }

  recomputeTotal() {
    let totalEuros = 0
    this.rowsTarget.querySelectorAll(".invoice__line").forEach((row) => {
      if (row.style.display === "none") return
      const qty  = parseFloat(row.querySelector("[name*='[quantity]']")?.value || 0)
      const rate = parseFloat(row.querySelector("[name*='[unit_amount]']")?.value || 0)
      if (Number.isFinite(qty) && Number.isFinite(rate)) {
        const lineTotal = qty * rate
        totalEuros += lineTotal

        const amountCell = row.querySelector(".invoice__line-amount")
        if (amountCell) {
          amountCell.textContent = `€${lineTotal.toFixed(2)}`
        }
      }
    })

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `€${totalEuros.toFixed(2)}`
    }
  }

  scheduleSubmit() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.submit(), AUTOSAVE_DEBOUNCE_MS)
  }

  submit() {
    const form = this.element.closest("form")
    if (!form) return
    form.requestSubmit()
  }

  // Wired to `turbo:submit-end` on the form. Flashes a "Saved · HH:MM" pill.
  submitEnded(event) {
    if (!this.hasSavedPillTarget) return
    const ok = event.detail?.success
    const time = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
    this.savedPillTarget.textContent = ok ? `Saved · ${time}` : "Save failed"
    this.savedPillTarget.dataset.state = ok ? "ok" : "error"
  }
}
