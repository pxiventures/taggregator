class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :original_id
      t.string :last_media_id

      t.timestamps
    end
  end
end
