class MakeCommentsAndLikesDefaultToZero < ActiveRecord::Migration
  def up
    change_column :photos, :comments, :integer, default: 0
    change_column :photos, :likes, :integer, default: 0
  end

  def down
    change_column :photos, :comments, :integer
    change_column :photos, :likes, :integer
  end
end
