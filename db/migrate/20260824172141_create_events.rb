class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :event_id, null: false
      t.string :object_type
      t.string :kind
      t.string :state, null: false
      t.string :title, null: false
      t.text :description
      t.string :url
      t.string :branded_url
      t.string :image_link
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :availability
      t.integer :price_amount_in_cents
      t.string :price_currency
      t.jsonb :organiser_data, default: {}
      t.jsonb :location_data, default: {}
      t.jsonb :categorization_data, default: {}
      t.jsonb :organization_data, default: {}
      t.jsonb :headliners_data, default: {}

      t.timestamps
    end
    # Indexes for Query performance
    add_index :events, :event_id, unique: true
    add_index :events, :start_date
    add_index :events, :state
    add_index :events, :availability
    add_index :events, :title
    add_index :events, :kind

    # JSONB indexes for querying
    add_index :events, "((location_data->>'city'))", name: 'index_events_on_city'
    add_index :events, "((categorization_data->>'category'))", name: 'index_events_on_category'
    add_index :events, "((organiser_data->>'id'))", name: 'index_events_on_organiser_id'
  end
end
