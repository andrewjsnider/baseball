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
    const playerId = event.target.dataset.playerId
    const position = event.target.value

    fetch(this.baseUrl + "/assign_positions", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({
        positions: { [playerId]: position }
      })
    }).then(() => {
      this.refreshDisabledOptions()
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
}
