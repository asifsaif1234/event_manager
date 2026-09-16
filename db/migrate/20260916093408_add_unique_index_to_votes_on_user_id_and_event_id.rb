class AddUniqueIndexToVotesOnUserIdAndEventId < ActiveRecord::Migration[8.1]
  def up
    # Remove existing duplicates first — the unique index will fail otherwise.
    execute <<~SQL.squish
      DELETE FROM votes
      WHERE id NOT IN (
        SELECT MAX(id) FROM votes GROUP BY user_id, event_id
      );
    SQL

    add_index :votes,
              [ :user_id, :event_id ],
              unique: true,
              name: "index_votes_on_user_id_and_event_id"
  end

  def down
    remove_index :votes, name: "index_votes_on_user_id_and_event_id"
  end
end
