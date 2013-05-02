class AddMediaAndFollowsAndFollowedByToUsers < ActiveRecord::Migration
  def change
    add_column :users, :media, :integer
    add_column :users, :follows, :integer
    add_column :users, :followed_by, :integer
  end
end
