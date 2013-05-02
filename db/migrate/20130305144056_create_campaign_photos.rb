class CreateCampaignPhotos < ActiveRecord::Migration
  def up
    create_table :campaign_photos do |t|
      t.integer :photo_id, allow_nil: false
      t.integer :campaign_id, allow_nil: false
      # Score has a maximum of 2 decimal places. Probably won't see a score of
      # more than 999999? :) Postgres seems to ignore this anyway.
      t.decimal :score, precision: 10, scale: 2, allow_nil: false

      t.timestamps
    end

    add_index :campaign_photos, :photo_id
    add_index :campaign_photos, :campaign_id
    add_index :campaign_photos, [:photo_id, :campaign_id], unique: true

    Campaign.find_each do |campaign|
      campaign.join_to_photos
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
