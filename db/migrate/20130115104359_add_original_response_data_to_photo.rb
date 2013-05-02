class AddOriginalResponseDataToPhoto < ActiveRecord::Migration
  def change
    add_column :photos, :original_response_data, :text
  end
end
