class CreateReceivedDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :received_documents do |t|
      t.string :kind,    null: false
      t.string :sender
      t.string :subject

      t.timestamps
    end

    add_index :received_documents, :kind
  end
end
