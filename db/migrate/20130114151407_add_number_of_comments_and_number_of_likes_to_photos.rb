class AddNumberOfCommentsAndNumberOfLikesToPhotos < ActiveRecord::Migration
  def change
    add_column :photos, :comments, :integer
    add_column :photos, :likes, :integer
  end
end
