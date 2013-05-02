class CreateCampaignTags < ActiveRecord::Migration
  def change
    create_table :campaign_tags do |t|
      t.references :campaign
      t.references :tag

      t.timestamps
    end
  end
end
