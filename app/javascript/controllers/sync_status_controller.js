import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "content"]

  async check() {
    this.displayTarget.classList.remove("hidden")
    try {
      const response = await fetch("/events/sync_status")
      const data = await response.json()
      if (data.success) {
        const lastRun = new Date(data.last_run).toLocaleString()
        const results = JSON.stringify(data.results, null, 2)
        this.contentTarget.innerHTML = `
          <div class="space-y-2">
            <p><strong>Last Run:</strong> ${lastRun}</p>
            <p><strong>Results:</strong></p>
            <pre class="bg-white p-2 rounded border border-gray-200 text-xs">${results}</pre>
          </div>
        `
      } else {
        this.contentTarget.innerHTML = `<p class="text-red-600">${data.message}</p>`
      }
    } catch (error) {
      this.contentTarget.innerHTML = `<p class="text-red-600">Error fetching sync status: ${error.message}</p>`
    }
  }

  hide() {
    this.displayTarget.classList.add("hidden")
  }
}