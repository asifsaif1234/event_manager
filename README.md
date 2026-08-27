# README

# Rails Assessment

## Tech Stack & Environment
* **Ruby**: 3.3.9
* **Node.js**: v23.10.0
* **npm**: v10.9.2
* **Ruby on Rails**: Rails 8.1.3.1
* **Database**: PostgreSQL

## Getting Started

### 1. Clone the repository
git clone https://github.com/asifsaif1234/event_manager.git
cd event_manager

### 2. Database Configuration
Ensure PostgreSQL is installed and running. Update your `config/database.yml` to configure your PostgreSQL credentials for development and test environments.

### 3. Install Dependencies
Run the following commands to install Ruby and Node dependencies:
```bash
bundle install
```

### 3. Database Setup
Create and migrate your PostgreSQL database:
```bash
rails db:create
rails db:migrate
```

### 4. Set up environment variables (CRITICAL)
## Copy the example file and fill in your Clerk and billeto keys
```bash
cp .env.example .env
```

### 5. Running the Project
bin/dev

---

### 2. Design Choices

Below is a summary of the key architectural decisions made during development.

#### Authentication (Clerk)
- **Use Clerk for Authentication:** I use Clerk as per the instruction the primary authentication provider. This handles user sign-in, session management, and security out-of-the-box.
- **Session-Based Access:** After successful Clerk authentication, I store `user_id` in the Rails session (`session[:user_id]`). This allows controllers to access the current user without re-querying Clerk on every request.
- **`ApplicationController` Helper:** We use a `current_user` method in `ApplicationController` that queries `clerk.user` and the database to load the user.

#### 🧱 Service Objects (VoteRecorder & Billetto Services)
- **`VoteRecorder` Service:** Voting logic (create/remove/change votes) is extracted into a dedicated service object (`VoteRecorder`). This ensures controllers stay thin and the voting logic is easily testable and reusable.
- **`EventIngestionService`:** Handles fetching and saving events from the Billetto API. It uses a "fetch and save" pattern.

#### 🗄️ Database Architecture
- **PostgreSQL:** Used for all relational data (events, votes, users).
- **Counter Cache:** `Event.upvotes_count` uses Rails' `counter_cache` to efficiently track upvotes without running expensive `COUNT` queries on every page load.

#### 📡 Event Store (RailsEventStore)
- **Event Sourcing:** We use `RailsEventStore` to publish domain events (e.g., `EventUpvoted`, `EventDownvoted`, `EventVoteRemoved`). This allows us to build a traceable history of votes and potentially integrate with external systems/analytics.

#### 🧪 Testing
- **RSpec:** We use RSpec for all testing (Models, Controllers, Services).
- **FactoryBot:** For creating test fixtures cleanly.
- **Shoulda Matchers:** For one-line validation and association tests.

---

### 3. Assumptions Made During Development

1. **Clerk is the Sole Authentication Provider:** I assume all user authentication flows through Clerk.

2. **Billetto API is the Only Event Source:** I assume events are only ingested from the Billetto API. There is no feature to add Events manually.

3. **Voting is Limited to Authenticated Users:** Voting actions require a signed-in user. Unauthenticated users can view events but cannot vote.

4. **Rails Event Store:** Events created as any operation done on voting for traceablity.

---

