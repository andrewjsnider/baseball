import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  submitOnChange(event) {
    // If a row-level Save button was clicked, let that flow handle it.
    if (event?.target?.dataset?.skipAutoSubmit === "true") return

    // Submit the form (Turbo will handle it if enabled; otherwise HTML submit)
    this.formTarget.requestSubmit()
  }

  submitOnlyRow(event) {
    const slotId = event.currentTarget.dataset.slotId
    const hidden = this.element.querySelector('input[name="only_slot_id"]')
    hidden.value = slotId
    this.formTarget.requestSubmit()
  }
}