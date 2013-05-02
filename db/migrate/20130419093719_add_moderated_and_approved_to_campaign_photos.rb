class AddModeratedAndApprovedToCampaignPhotos < ActiveRecord::Migration
  def up
    add_column :campaign_photos, :moderated, :boolean, allow_nil: false, default: false
    add_column :campaign_photos, :approved, :boolean, allow_nil: false

    CampaignPhoto.find_each do |cp|
      cp.update_attribute(:approved, cp.campaign.default_approved_state)
    end
  end

  def down
    remove_column :campaign_photos, :moderated
    remove_column :campaign_photos, :approved
  end

end
