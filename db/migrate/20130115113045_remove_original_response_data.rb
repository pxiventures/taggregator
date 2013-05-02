class RemoveOriginalResponseData < ActiveRecord::Migration
  def up
    remove_column :photos, :original_response_data
  end

  def down
    add_column :photos, :original_response_data, :text
  end
end
