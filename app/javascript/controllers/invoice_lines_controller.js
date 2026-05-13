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
  static targets = ["rows", "template", "subtotal", "taxAmount", "grandTotal", "savedPill"]

  connect() {
    this._timer = null
    this.recomputeTotal()
    this.#restoreScrollIfNeeded()
  }

  // After auto-save, Turbo navigates to the redirected URL and resets
  // scroll to top by default. We stash window.scrollY before submit and
  // restore it on the next connect() to preserve the user's position —
  // critical on mobile where the form is taller than the viewport.
  #restoreScrollIfNeeded() {
    const saved = sessionStorage.getItem("brain.invoice.scrollY")
    if (saved == null) return
    sessionStorage.removeItem("brain.invoice.scrollY")
    requestAnimationFrame(() => window.scrollTo(0, parseInt(saved, 10)))
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
    // Money formatter: en-US so the "." stays the decimal regardless of
    // browser locale, matches the server-side display_money helper.
    const eur = new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })

    let subtotal = 0
    this.rowsTarget.querySelectorAll(".invoice__line").forEach((row) => {
      if (row.style.display === "none") return
      // Inputs are comma-tolerant: parse "650,00" the same as "650.00".
      const qtyRaw  = row.querySelector("[name*='[quantity]']")?.value || ""
      const rateRaw = row.querySelector("[name*='[unit_amount]']")?.value || ""
      const qty  = parseFloat(qtyRaw.replace(",", "."))
      const rate = parseFloat(rateRaw.replace(",", "."))
      if (Number.isFinite(qty) && Number.isFinite(rate)) {
        const lineTotal = qty * rate
        subtotal += lineTotal

        const amountCell = row.querySelector(".invoice__line-amount")
        if (amountCell) {
          amountCell.textContent = `€${eur.format(lineTotal)}`
        }
      }
    })

    const totalsEl = this.element.querySelector(".invoice__totals")
    const taxRate  = parseFloat(totalsEl?.dataset.taxRate || 0)
    const taxAmt   = subtotal * taxRate
    const total    = subtotal + taxAmt

    if (this.hasSubtotalTarget)   this.subtotalTarget.textContent   = `€${eur.format(subtotal)}`
    if (this.hasTaxAmountTarget)  this.taxAmountTarget.textContent  = `€${eur.format(taxAmt)}`
    if (this.hasGrandTotalTarget) this.grandTotalTarget.textContent = `€${eur.format(total)}`
  }

  scheduleSubmit() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.submit(), AUTOSAVE_DEBOUNCE_MS)
  }

  submit() {
    const form = this.element.closest("form")
    if (!form) return
    sessionStorage.setItem("brain.invoice.scrollY", String(window.scrollY))
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
