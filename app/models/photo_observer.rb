class PhotoObserver < ActiveRecord::Observer
  observe :photo

  def after_save(photo)
    photo.join_to_campaigns
    photo.campaign_photos.each(&:update_score)
  end

  def after_touch(photo)
    photo.join_to_campaigns
    photo.campaign_photos.each(&:update_score)
  end

end
