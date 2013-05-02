class AddUniqueTagIdPhotoIdIndexToPhotoTags < ActiveRecord::Migration
  def change
    add_index :photo_tags, [:tag_id, :photo_id], unique: true
  end
end
