class AddFieldsToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :start_date, :datetime, allow_nil: false
    add_column :campaigns, :end_date, :datetime, allow_nil: false
    add_column :campaigns, :winning_photo_id, :integer
    add_column :campaigns, :sent_new_campaign_email, :boolean, default: false, allow_nil: false
    add_column :campaigns, :sent_winner_email, :boolean, default: false, allow_nil: false
  end
end
