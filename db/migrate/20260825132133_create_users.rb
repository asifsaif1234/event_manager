class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :clerk_id, null: false, index: { unique: true }
      t.string :primary_email_id

      t.string :email, null: false, index: { unique: true }
      t.string :first_name
      t.string :last_name
      t.string :full_name
      t.string :avatar_url

      t.integer :status, default: 0
      t.boolean :banned, default: false
      t.boolean :locked, default: false

      t.jsonb :public_metadata, default: {}
      t.jsonb :private_metadata, default: {}
      t.jsonb :external_accounts, default: []

      t.datetime :last_sign_in_at
      t.datetime :last_active_at
      t.datetime :last_synced_at

      t.timestamps
    end
    add_index :users, [ :clerk_id, :email ]
    add_index :users, :status
    add_index :users, :last_sign_in_at
  end
end
