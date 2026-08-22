class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.string :actor
      t.string :action
      t.references :post, null: false, foreign_key: true
      t.json :details

      t.timestamps
    end
  end
end
