import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Event Voting Controller Connected!")
  }

  async vote(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const eventId = button.dataset.eventId;
    const voteType = button.dataset.voteType;
    const isAuthenticated = button.dataset.authenticated === 'true';
    const card = this.element; // The element with data-controller="event-voting"

    button.disabled = true;
    button.style.opacity = '0.6';

    try {
      if (!isAuthenticated) {
        this.showLoginPrompt();
        button.disabled = false;
        button.style.opacity = '1';
        return;
      }

      const upvoteBtn = card.querySelector('.upvote-btn');
      const downvoteBtn = card.querySelector('.downvote-btn');
      const upvoteCount = card.querySelector('.upvote-count');
      const downvoteCount = card.querySelector('.downvote-count');
      const scoreElement = card.querySelector('.vote-score');

      // Get current state
      const upvotes = upvoteCount ? parseInt(upvoteCount.textContent) || 0 : 0;
      const downvotes = downvoteCount ? parseInt(downvoteCount.textContent) || 0 : 0;
      let currentUserVote = null;
      if (upvoteBtn && upvoteBtn.classList.contains('bg-green-100')) currentUserVote = 'upvote';
      else if (downvoteBtn && downvoteBtn.classList.contains('bg-red-100')) currentUserVote = 'downvote';

      // Optimistic update
      let optimisticUpvotes = upvotes, optimisticDownvotes = downvotes, optimisticUserVote = currentUserVote;

      if (currentUserVote === voteType) {
        if (voteType === 'upvote') { optimisticUpvotes = Math.max(0, optimisticUpvotes - 1); optimisticUserVote = null; }
        else { optimisticDownvotes = Math.max(0, optimisticDownvotes - 1); optimisticUserVote = null; }
      } else if (currentUserVote === null) {
        if (voteType === 'upvote') { optimisticUpvotes += 1; optimisticUserVote = 'upvote'; }
        else { optimisticDownvotes += 1; optimisticUserVote = 'downvote'; }
      } else {
        if (voteType === 'upvote') { optimisticUpvotes += 1; optimisticDownvotes = Math.max(0, optimisticDownvotes - 1); optimisticUserVote = 'upvote'; }
        else { optimisticDownvotes += 1; optimisticUpvotes = Math.max(0, optimisticUpvotes - 1); optimisticUserVote = 'downvote'; }
      }

      // Apply optimistic update
      if (upvoteCount) upvoteCount.textContent = optimisticUpvotes;
      if (downvoteCount) downvoteCount.textContent = optimisticDownvotes;
      if (scoreElement) scoreElement.textContent = optimisticUpvotes - optimisticDownvotes;

      if (upvoteBtn) { upvoteBtn.classList.remove('bg-green-100', 'text-green-700'); upvoteBtn.classList.add('bg-gray-100', 'text-gray-600'); }
      if (downvoteBtn) { downvoteBtn.classList.remove('bg-red-100', 'text-red-700'); downvoteBtn.classList.add('bg-gray-100', 'text-gray-600'); }
      if (optimisticUserVote === 'upvote' && upvoteBtn) upvoteBtn.classList.add('bg-green-100', 'text-green-700');
      else if (optimisticUserVote === 'downvote' && downvoteBtn) downvoteBtn.classList.add('bg-red-100', 'text-red-700');

      // Send request
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';
      const response = await fetch(`/events/${eventId}/vote`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken },
        body: JSON.stringify({ vote_type: voteType })
      });

      const data = await response.json();

      if (data.error === 'login_required') {
        this.rollback(card, upvotes, downvotes, currentUserVote);
        this.showLoginPrompt();
        button.disabled = false; button.style.opacity = '1';
        return;
      }

      if (data.success) {
        if (upvoteCount) upvoteCount.textContent = data.upvotes;
        if (downvoteCount) downvoteCount.textContent = data.downvotes;
        if (scoreElement) scoreElement.textContent = data.total_score;
        
        if (upvoteBtn) { upvoteBtn.classList.remove('bg-green-100', 'text-green-700'); upvoteBtn.classList.add('bg-gray-100', 'text-gray-600'); }
        if (downvoteBtn) { downvoteBtn.classList.remove('bg-red-100', 'text-red-700'); downvoteBtn.classList.add('bg-gray-100', 'text-gray-600'); }
        
        if (data.user_vote === 'upvote' && upvoteBtn) upvoteBtn.classList.add('bg-green-100', 'text-green-700');
        else if (data.user_vote === 'downvote' && downvoteBtn) downvoteBtn.classList.add('bg-red-100', 'text-red-700');
        
        if (data.message) this.showToast(data.message, 'success');
      } else {
        this.rollback(card, upvotes, downvotes, currentUserVote);
        this.showToast(data.message || 'Something went wrong', 'error');
      }
    } catch (error) {
      this.rollback(card, upvotes, downvotes, currentUserVote);
      this.showToast('Network error. Please try again.', 'error');
    } finally {
      button.disabled = false;
      button.style.opacity = '1';
    }
  }

  rollback(card, upvotes, downvotes, currentUserVote) {
    const upvoteCount = card.querySelector('.upvote-count');
    const downvoteCount = card.querySelector('.downvote-count');
    const scoreElement = card.querySelector('.vote-score');
    const upvoteBtn = card.querySelector('.upvote-btn');
    const downvoteBtn = card.querySelector('.downvote-btn');

    if (upvoteCount) upvoteCount.textContent = upvotes;
    if (downvoteCount) downvoteCount.textContent = downvotes;
    if (scoreElement) scoreElement.textContent = upvotes - downvotes;

    if (upvoteBtn) { upvoteBtn.classList.remove('bg-green-100', 'text-green-700'); upvoteBtn.classList.add('bg-gray-100', 'text-gray-600'); }
    if (downvoteBtn) { downvoteBtn.classList.remove('bg-red-100', 'text-red-700'); downvoteBtn.classList.add('bg-gray-100', 'text-gray-600'); }
    if (currentUserVote === 'upvote' && upvoteBtn) upvoteBtn.classList.add('bg-green-100', 'text-green-700');
    else if (currentUserVote === 'downvote' && downvoteBtn) downvoteBtn.classList.add('bg-red-100', 'text-red-700');
  }

  showLoginPrompt() {
    const existing = document.querySelector('.login-modal');
    if (existing) existing.remove();
    const modal = document.createElement('div');
    modal.className = 'login-modal fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 animate-fadeIn';
    modal.innerHTML = `
      <div class="bg-white rounded-2xl p-8 max-w-md w-full mx-4 shadow-2xl">
        <div class="text-center">
          <div class="text-5xl mb-4">🔒</div>
          <h2 class="text-2xl font-bold text-gray-900 mb-2">Sign In Required</h2>
          <p class="text-gray-600 mb-6">You need to sign in to vote on events.</p>
          <div class="flex flex-col sm:flex-row gap-3">
            <a href="/sign_in" class="flex-1 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-center font-medium transition-colors">Sign In</a>
            <a href="/sign_up" class="flex-1 px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-800 rounded-lg text-center font-medium transition-colors">Sign Up</a>
            <button onclick="this.closest('.login-modal').remove()" class="px-4 py-2 text-gray-500 hover:text-gray-700 transition-colors">Cancel</button>
          </div>
        </div>
      </div>
    `;
    modal.addEventListener('click', function(e) { if (e.target === this) this.remove(); });
    document.body.appendChild(modal);
  }

  showToast(message, type = 'success') {
    document.querySelectorAll('.toast-message').forEach(el => el.remove());
    const colors = { success: 'bg-green-600', warning: 'bg-yellow-600', error: 'bg-red-600', info: 'bg-blue-600' };
    const toast = document.createElement('div');
    toast.className = `toast-message fixed bottom-4 right-4 ${colors[type] || 'bg-gray-900'} text-white px-6 py-3 rounded-lg shadow-lg z-50`;
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => { toast.style.opacity = '0'; setTimeout(() => toast.remove(), 300); }, 2500);
  }
}