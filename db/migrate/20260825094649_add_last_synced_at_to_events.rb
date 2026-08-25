class AddLastSyncedAtToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :last_synced_at, :datetime
  end
end
