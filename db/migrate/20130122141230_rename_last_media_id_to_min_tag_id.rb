class RenameLastMediaIdToMinTagId < ActiveRecord::Migration
  def up
    rename_column :subscriptions, :last_media_id, :min_tag_id
  end

  def down
    rename_column :subscriptions, :min_tag_id, :last_media_id
  end
end
