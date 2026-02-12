// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import Sortable from "sortablejs"

document.addEventListener("turbo:load", () => {
  const el = document.getElementById("batting-order")
  if (!el) return

  Sortable.create(el, {
    animation: 150,
    onEnd: function () {
      const playerIds = [...el.children].map(
        (item) => item.dataset.playerId
      )

      fetch(el.dataset.updateUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document
            .querySelector("meta[name=csrf-token]")
            .content
        },
        body: JSON.stringify({ player_ids: playerIds })
      })
    }
  })
})

