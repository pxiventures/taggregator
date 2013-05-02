class AddQueuedToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :queued, :integer, null: false, default: 0
  end
end
