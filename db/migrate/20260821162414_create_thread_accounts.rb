class CreateThreadAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :thread_accounts do |t|
      t.string :threads_user_id, null: false
      t.string :username, null: false
      t.string :access_token, null: false
      t.datetime :token_expires_at

      t.timestamps
    end

    add_index :thread_accounts, :threads_user_id, unique: true
  end
end
