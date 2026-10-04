import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async logout() {
    try {
      if (!window.Clerk) {
        throw new Error("ClerkJS is not loaded")
      }
      console.log("[Clerk Logout] ✅ window.Clerk is available:", window.Clerk)

      await window.Clerk.load()

      await window.Clerk.signOut({
        redirectUrl: "/"
      })
    } catch (error) {
      console.error("Clerk sign-out failed:", error)
    }
  }
}
