class AddIndexes < ActiveRecord::Migration
  def change
    add_index :campaign_tags, :campaign_id
    add_index :campaign_tags, :tag_id
    add_index :photo_tags, :tag_id
    add_index :photo_tags, :photo_id
    add_index :photos, :user_id
    add_index :photos, :uid, unique: true
    add_index :tags, :name, unique: true
    add_index :users, :uid, unique: true
    add_index :users, :username
  end
end
