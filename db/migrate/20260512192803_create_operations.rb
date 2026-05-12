class CreateOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :operations do |t|
      t.string  :kind,            null: false
      t.string  :status,          null: false, default: "pending"
      t.integer :attempt_count,   null: false, default: 0
      t.integer :max_attempts,    null: false, default: 5
      t.string  :adapter_name,    null: false
      t.string  :correlation_id

      t.json    :input,           null: false, default: {}
      t.json    :output
      t.text    :error

      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :operations, [ :kind, :status ]
    add_index :operations, [ :status, :attempt_count ]
    add_index :operations, :correlation_id
  end
end
