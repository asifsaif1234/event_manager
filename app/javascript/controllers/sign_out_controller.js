import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    redirectUrl: { type: String, default: "/" } 
  }

  connect() {
    console.log("✅ Sign Out Controller Connected!")
    console.log("📌 Element:", this.element)
    console.log("📌 Clerk available:", !!window.Clerk)
    console.log("📌 Redirect URL:", this.redirectUrlValue)
  }

  async signOut(event) {
    event.preventDefault()
    

    // Check if Clerk is available
    if (!window.Clerk) {
      console.error("❌ Clerk is not available!")
      console.log("🔄 Redirecting to:", this.redirectUrlValue)
      window.location.href = this.redirectUrlValue
      return
    }

    console.log("✅ Clerk is available")

    try {
      // Get CSRF token
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      console.log("🔑 CSRF Token:", token ? "✅ Found" : "❌ Not found")

      // Step 1: Call Rails server
      console.log("📡 Step 1: Calling Rails server at /sign-out...")
      const response = await fetch("/sign-out", { 
        method: "DELETE", 
        headers: { 
          "X-CSRF-Token": token || "",
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        credentials: "same-origin"
      })

      console.log(`📡 Server response status: ${response.status}`)
      console.log(`📡 Server response OK: ${response.ok}`)

      if (!response.ok) {
        throw new Error(`Server returned ${response.status}`)
      }

      console.log("✅ Step 1 complete: Rails session cleared")

      // Step 2: Sign out from Clerk
      console.log("🔐 Step 2: Signing out from Clerk...")
      await window.Clerk.signOut({ 
        redirectUrl: this.redirectUrlValue 
      })

      console.log("✅ Step 2 complete: Clerk signed out")
      console.log("=================================")
      console.log("✅ SIGN OUT SUCCESSFUL")
      console.log("=================================")

    } catch (error) {
      console.error("=================================")
      console.error("❌ SIGN OUT ERROR:", error)
      console.error("=================================")
      
      // Fallback: manually redirect
      console.log("🔄 Fallback redirecting to:", this.redirectUrlValue)
      window.location.href = this.redirectUrlValue
    }
  }
}