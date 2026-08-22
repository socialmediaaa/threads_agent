class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :thread_account, null: false, foreign_key: true
      t.text :content, null: false
      t.string :media_url
      t.integer :status, null: false, default: 0
      t.datetime :scheduled_at
      t.datetime :published_at
      t.string :threads_media_id
      t.string :threads_post_id
      t.text :error_message

      t.timestamps
    end

    add_index :posts, [ :status, :scheduled_at ]
  end
end
