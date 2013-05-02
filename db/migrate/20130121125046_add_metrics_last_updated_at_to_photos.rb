class AddMetricsLastUpdatedAtToPhotos < ActiveRecord::Migration
  def change
    add_column :photos, :metrics_last_updated_at, :datetime
  end
end
