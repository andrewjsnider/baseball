import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    this.baseUrl = this.element.dataset.lineupUrl

    Sortable.create(this.element, {
      animation: 150,
      onEnd: this.updateOrder.bind(this)
    })

    this.refreshDisabledOptions()
    this.cacheSelectValues()
  }

  cacheSelectValues() {
    const selects = this.element.querySelectorAll("select")
    selects.forEach((select) => {
      select.dataset.prevValue = select.value
    })
  }

  updateOrder() {
    const playerIds = Array.from(this.element.children)
      .map(el => el.dataset.playerId)

    fetch(this.baseUrl + "/reorder", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ player_ids: playerIds })
    })
  }

  updatePosition(event) {
    const select = event.target
    const playerId = select.dataset.playerId
    const position = select.value
    const prevValue = select.dataset.prevValue || ""

    this.clearInlineError(select)

    fetch(this.baseUrl + "/assign_positions", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ positions: { [playerId]: position } })
    })
      .then(async (response) => {
        if (response.ok) {
          select.dataset.prevValue = position
          this.refreshDisabledOptions()
          return
        }

        if (response.status === 422) {
          const data = await response.json().catch(() => ({}))
          const msg =
            (data.errors && data.errors[0]) ||
            data.error ||
            "Could not assign that position."

          select.value = prevValue
          this.refreshDisabledOptions()
          this.showInlineError(select, msg)
          this.showFlash(msg)
          return
        }

        select.value = prevValue
        this.refreshDisabledOptions()
        this.showFlash("Something went wrong saving the position.")
      })
      .catch(() => {
        select.value = prevValue
        this.refreshDisabledOptions()
        this.showFlash("Network error saving the position.")
      })
  }

  refreshDisabledOptions() {
    const selects = this.element.querySelectorAll("select")

    const selectedPositions = Array.from(selects)
      .map(select => select.value)
      .filter(value => value !== "")

    selects.forEach(select => {
      Array.from(select.options).forEach(option => {
        if (option.value === "") return

        if (selectedPositions.includes(option.value) && select.value !== option.value) {
          option.disabled = true
        } else {
          option.disabled = false
        }
      })
    })
  }

  updatePitchLimit(event) {
    const value = event.target.value

    fetch(this.baseUrl + "/update_pitch_limit", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ planned_pitch_limit: value })
    })
  }

  showFlash(message) {
    const flash = document.getElementById("flash")
    if (!flash) return

    flash.innerHTML = `
      <div class="border border-red-400 p-3 mb-4 text-sm text-red-700">
        ${this.escapeHtml(message)}
      </div>
    `
  }

  showInlineError(select, message) {
    const el = document.createElement("div")
    el.className = "mt-1 text-xs text-red-600"
    el.dataset.lineupError = "true"
    el.textContent = message
    select.parentElement.appendChild(el)
  }

  clearInlineError(select) {
    const existing = select.parentElement.querySelector('[data-lineup-error="true"]')
    if (existing) existing.remove()
  }

  escapeHtml(str) {
    return String(str)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;")
  }
}
