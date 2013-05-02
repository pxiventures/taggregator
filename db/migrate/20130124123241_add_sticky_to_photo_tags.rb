class AddStickyToPhotoTags < ActiveRecord::Migration
  def change
    add_column :photo_tags, :sticky, :boolean, default: false
  end
end
