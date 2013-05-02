class RemoveEmailFlagsFromCampaigns < ActiveRecord::Migration
  def up
    remove_column :campaigns, :sent_winner_email
    remove_column :campaigns, :sent_new_campaign_email
  end

  def down
    add_column :campaigns, :sent_winner_email, :boolean, default: false
    add_column :campaigns, :sent_new_campaign_email, :boolean, default: false
  end
end
