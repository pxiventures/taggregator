class AddTagToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :tag, :string
  end
end
