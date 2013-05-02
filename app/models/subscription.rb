# Public: A Subscription is a representation of a subscription to Instagram's
# realtime API for a particular tag.
#
# It maintains information about how many new photos Instagram has told us
# about, once this reaches a certain threshold (defined in the config) it fires
# off an asynchronous job to fetch new photos from Instagram. This keeps the
# API usage reasonably low.
class Subscription < ActiveRecord::Base
  attr_accessible :tag, :original_id, :min_tag_id

  def queue_fetch
    self.async_fetch_photos
  end

  def async_fetch_photos
    Star::SubscriptionWorker.perform_async(self.id)
  end


end
