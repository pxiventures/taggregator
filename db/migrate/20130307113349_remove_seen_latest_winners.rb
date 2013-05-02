class RemoveSeenLatestWinners < ActiveRecord::Migration
  def change
    remove_column :users, :seen_latest_winners
  end
end
