class AddMetricsLastUpdatedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :metrics_last_updated_at, :datetime
  end
end
