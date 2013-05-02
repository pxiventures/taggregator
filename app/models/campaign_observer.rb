class CampaignObserver < ActiveRecord::Observer
  observe :campaign
  
  def after_save(campaign)
    campaign.join_to_photos
    campaign.campaign_photos.each(&:touch)
  end

  def after_touch(campaign)
    campaign.join_to_photos
    campaign.campaign_photos.each(&:touch)
  end

end
