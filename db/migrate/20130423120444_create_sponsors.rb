class CreateSponsors < ActiveRecord::Migration
  def change
    create_table :sponsors do |t|
      t.string :name
      t.integer :user_id
      t.string :url
      t.string :logo

      t.timestamps
    end

    add_column :campaigns, :sponsor_id, :integer
  end
end
