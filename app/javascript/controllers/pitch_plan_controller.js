import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  submitOnChange(event) {
    if (event?.target?.dataset?.skipAutoSubmit === "true") return
    this.formTarget.requestSubmit()
  }

  submitOnlyRow(event) {
    event.preventDefault()

    const button = event.currentTarget
    const slotId = button.dataset.slotId
    const row = button.closest("[data-pitch-plan-row]")

    if (!row || !slotId) return

    const tempForm = document.createElement("form")
    tempForm.method = "post"
    tempForm.action = this.formTarget.action
    tempForm.style.display = "none"

    const csrfParamMeta = document.querySelector('meta[name="csrf-param"]')
    const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]')

    if (csrfParamMeta && csrfTokenMeta) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = csrfParamMeta.content
      csrfInput.value = csrfTokenMeta.content
      tempForm.appendChild(csrfInput)
    } else {
      const existingToken = this.formTarget.querySelector('input[name="authenticity_token"]')
      if (existingToken) {
        tempForm.appendChild(existingToken.cloneNode())
      }
    }

    const methodInput = document.createElement("input")
    methodInput.type = "hidden"
    methodInput.name = "_method"
    methodInput.value = "patch"
    tempForm.appendChild(methodInput)

    const onlySlotInput = document.createElement("input")
    onlySlotInput.type = "hidden"
    onlySlotInput.name = "only_slot_id"
    onlySlotInput.value = slotId
    tempForm.appendChild(onlySlotInput)

    row.querySelectorAll("input[name], select[name], textarea[name]").forEach((field) => {
      if (field.disabled) return

      if ((field.type === "checkbox" || field.type === "radio") && !field.checked) return

      const clone = document.createElement("input")
      clone.type = "hidden"
      clone.name = field.name
      clone.value = field.value
      tempForm.appendChild(clone)
    })

    document.body.appendChild(tempForm)
    tempForm.requestSubmit()
  }
}
