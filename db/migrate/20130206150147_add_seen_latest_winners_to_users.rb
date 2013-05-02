class AddSeenLatestWinnersToUsers < ActiveRecord::Migration
  def change
    add_column :users, :seen_latest_winners, :boolean, default: true, allow_nil: false
  end
end
