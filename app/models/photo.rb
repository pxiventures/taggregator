# Public: A photo from Instagram.
class Photo < ActiveRecord::Base

  attr_accessible :uid, :url, :user, :image_url, :thumbnail_url, :created_at,
    :comments, :likes, :caption

  belongs_to :user
  has_one :won_campaign, class_name: Campaign, inverse_of: :winning_photo, foreign_key: "winning_photo_id"

  has_many :photo_tags, dependent: :destroy
  # uniq doesn't actually enforce uniqueness, it just uses DISTINCT.
  has_many :tags, through: :photo_tags, uniq: true

  has_many :campaign_photos, dependent: :destroy
  has_many :campaigns, through: :campaign_photos

  has_many :approved_campaigns,
    through: :campaign_photos,
    source: :campaign,
    class_name: Campaign,
    conditions: {
      campaign_photos: {
        approved: true
      }
    }

  validates :uid, uniqueness: true

  # Public: Set all the attributes that are from Instagram. Can be used to
  # update the photo as well as create it from nothing.
  def set_attributes_from_instagram(data)
    self.uid = data.id
    # 2013/03/28 Instagram silently changed their API so these are just
    # strings.
    if data.images.standard_resolution.is_a? String
      self.image_url = data.images.standard_resolution
      self.thumbnail_url = data.images.thumbnail
    else
      self.image_url = data.images.standard_resolution.url
      self.thumbnail_url = data.images.thumbnail.url
    end
    self.url = data.link
    self.created_at = Time.at(data.created_time.to_i)
    self.comments = self.real_comment_count(data)
    self.likes = self.real_like_count(data)
    self.caption = data.caption.text rescue nil
    self.metrics_last_updated_at = Time.now
  end

  # Public: Set/update photo tags. Deletes any tags that the photo is no longer
  # tagged with.
  #
  # Returns array of tags.
  def update_tags_from_instagram(instagram_tags)
    current_tags = Tag.joins(:photo_tags).where(:photo_tags => {:photo_id => self.id, :sticky => false})
    new_tags = instagram_tags.map do |tag|
      Tag.find_or_create_by_name(tag)
    end
    self.tags.destroy(*(current_tags - new_tags))
    self.tags += new_tags
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn "I violated a unique key constraint when updating photo tags"
  end

  # Public: Queue a photo for an update
  def queue_for_updates(force=false)
    Star::PhotoUpdater::Updater.perform_async(self.id, force) if force || self.need_to_update_metrics?
  end

  # Internal: Returns whether the photo needs to have its metrics updated based
  # on the time they were last updated (or if they have never been fetched).
  def need_to_update_metrics?
    days_old = self.days_between(Time.now)
    ttl = AppConfig.photo_metrics_ttl * (days_old < 0 ? ((-days_old)+1) : 1)
    !self.metrics_last_updated_at || self.metrics_last_updated_at < ttl.ago
  end

  # Public: Update the photo's metrics from Instagram
  #
  # return_response -  Whether to return the Faraday response object. Defaults
  #   to false (and returns the photo instead). Used by
  #   Star::PhotoUpdater::Updater.
  #
  # Returns the photo if successful, nil if not. If return_response is true
  # it will return the API response object instead.
  def update_metrics(return_response = false)

    params = {client_id: AppConfig.instagram.client_id}
    # If photo has a user with creds, make the request as them
    params[:access_token] = self.user.access_token if self.user and self.user.access_token

    begin
      response = Star::Requester.get "media/#{self.uid}", params
    rescue Faraday::Error::ResourceNotFound
      puts "Instagram API issue. Ignoring"
      nil
    rescue Faraday::Error::ClientError => e
      if e.message =~ /400/
        # Letting this raise an exception if the Instagram API isn't returning
        # JSON.
        data = JSON.parse(e.response[:body])

        case data["meta"]["error_type"]
        when "APINotAllowedError"
          puts "Photo private...deleting #{self.uid}"
          self.destroy
        when "APINotFoundError"
          puts "Photo deleted...deleting #{self.uid}"
          self.destroy
        else
          puts "Unknown error type: #{data["meta"]["error_type"]}, ignoring"
        end

        nil
      end
    else

      if response.success? and response.body.data

        photo_data = response.body.data
        comments = self.real_comment_count(photo_data)
        likes = self.real_like_count(photo_data)

        self.set_attributes_from_instagram(response.body.data)
        self.update_tags_from_instagram(response.body.data.tags)
        self.save

        return return_response ? response : self

      else
        logger.warn "Tried to update metrics for #{self.uid} but failed: #{response.body}"
      end
    end
  end

  # The two methods below attempt to discount comments / likes that are
  # fraudulent, e.g. comments from the same user or a like from the user
  # themselves.
  #
  # However if the comment / likes count is above a certain threshold, we don't
  # bother because the difference in score will be negligible (as the photo is
  # going to win anyway) and Instagram won't give us the full set of data.
  def real_comment_count(photo_data)
    # Don't know what the maximum Instagram will give us is, let's pretend it's
    # 20.
    return photo_data.comments['count'] if photo_data.comments['count'] > 20

    # This is getting copy-pasta...
    params = {client_id: AppConfig.instagram.client_id}
    # If photo has a user with creds, make the request as them
    params[:access_token] = self.user.access_token if self.user and self.user.access_token

    begin
      response = Star::Requester.get "media/#{self.uid}/comments", params
      if response.success? and response.body.data
        return response.body.data
          .select{|comment| comment.from.id != photo_data.user.id}
          .uniq_by{|c| c.from.id}.length
      else
        raise "/media/{id}/comments was not a success: #{response.body.inspect}"
      end
    rescue Faraday::Error::ResourceNotFound, Faraday::Error::ClientError
      return photo_data.comments['count']
    end
  end

  # As above
  def real_like_count(photo_data)
    # Instagram only returns 200 likes.
    return photo_data.likes['count'] if photo_data.likes['count'] > 200

    # This is getting copy-pasta...
    params = {client_id: AppConfig.instagram.client_id}
    # If photo has a user with creds, make the request as them
    params[:access_token] = self.user.access_token if self.user and self.user.access_token
    begin
      response = Star::Requester.get "media/#{self.uid}/likes", params
      if response.success? and response.body.data
        return response.body.data.select{|like| like.id != photo_data.user.id}.length
      else
        raise "/media/{id}/likes was not a success: #{response.body.inspect}"
      end
    rescue Faraday::Error::ResourceNotFound, Faraday::Error::ClientError
      return photo_data.likes['count']
    end
   
  end

  # Override accessors for metrics to update metrics automatically as they are
  # accessed. Similar to code in user.rb - consider refactoring.
  [:comments, :likes].each do |field|
    define_method field do |*args|
      queue_for_updates
      super(*args)
    end
  end

  # Public: The 'score' formula that returns a value corresponding to how good
  # this photo is. Higher is better.
  #
  # Supply a campaign to use the campaign's start date as part of the scoring.
  def score(campaign=nil)
    Rails.cache.fetch([self, "score", campaign]) do
      log_score(campaign)
    end
  rescue ArgumentError => e # Comparison of nil 
    0.0
  end

  def log_score(campaign)
    lr = 1.0 * (self.likes + self.comments * 2) / Math.log([3, self.user.followed_by].max)
    if self.tags.count > AppConfig.photo_tags_maximum
      # Apply an exponential decay based on the number of tags.
      lr = lr * (Math::E ** (AppConfig.photo_tags_decay_constant * -[(self.tags.count - AppConfig.photo_tags_maximum), AppConfig.photo_tags_maximum_punish].min))
    end
    if campaign and self.created_at < campaign.start_date
      # Apply an exponential decay based on the days before the campaign started
      lr = lr * (Math::E ** (AppConfig.photo_date_decay_constant * self.days_between(campaign.start_date)))
    end
    # Half it if the user is not a member
    lr = lr / 4 unless self.user.member?
    return 0 if lr.nan?
    lr
  end

  # Public: Count the days between this photo's created at date and the start
  # of another date.
  #
  # For example, if the photo was taken 2 days before the date.
  # # => -2
  #
  # Or if it was created 1 day after
  # # => 1
  def days_between(date)
    ((self.created_at - date) / 86400).round
  end

  # Public: Create a photo from Instagram data. See
  # #create_or_update_from_instagram.
  def self.create_from_instagram(*args)
    self.create_or_update_from_instagram(*args)
  end

  # Public: Create or update a photo from Instagram data.
  def self.create_or_update_from_instagram(data, user=nil)
    photo = Photo.find_by_uid(data.id) || Photo.new
    is_new = photo.new_record?
    photo.set_attributes_from_instagram(data)
    photo.update_tags_from_instagram(data.tags)
    if user == nil
      user = User.find_by_uid(data.user.id) || User.create_with_instagram(data.user)
    end
    photo.user = user
    photo.save!
    # Queue an update in 1 minute if this was a new photo.
    Star::PhotoUpdater::Updater.perform_in(1.minute, photo.id) if is_new
    return photo
  end

  # Internal: Refresh join models between this photo and its campaigns.
  def join_to_campaigns
    # Inverse of #join_to_photos.
    # Source: http://stackoverflow.com/questions/8425232/sql-select-all-rows-where-subset-exists
    return true if self.photo_tags.count == 0
    in_campaigns = Campaign.joins(:campaign_tags)
      .select("campaigns.*, COUNT(campaigns.id)")
      .where(
        "campaign_tags.tag_id IN (:tags) and campaigns.end_date > :created_at",
        {tags: self.tags(true),
         created_at: self.created_at})
      .group("campaigns.id")
      .having("COUNT(campaigns.id) = (SELECT count(*) from campaign_tags WHERE campaign_tags.campaign_id = campaigns.id)")

    # Force a reload (hmm)
    self.campaigns(true)
    self.campaigns = in_campaigns
  end

  # Public: Return the position of this photo in a campaign. Returns false
  # if the photo is not in the campaign.
  def position_in(campaign)
    return false unless self.campaigns.include? campaign
    (@positions_in ||= {})[campaign.id] ||= campaign.ranked_photos.index{|p| p == self} + 1
  end

  # Public: Add the photo to a campaign.
  #
  # campaign - the campaign to add the photo to
  #
  # Returns an array of the tags that the photo is now tagged with, or false
  # if there was an error. Errors are added to the photo model, so use
  # #errors to inspect what went wrong.
  def add_to_campaign(campaign)
    if self.created_at > campaign.end_date
      errors.add(:created_at, "is after the end of the competition")
      return false
    end

    existing_join = self.campaign_photos.where(campaign_id: campaign.id).first
    if existing_join and (existing_join.moderated? and !existing_join.approved?)
      errors.add(:photo, "was previously not approved for that competition")
      return false
    elsif existing_join
      errors.add(:compeition, "already contains that photo")
      return false
    end

    # Existing tags that need to be made sticky
    (campaign.tags & self.tags).each do |t|
      self.photo_tags.find_by_tag_id(t.id).update_attribute(:sticky, true)
    end

    # Now add the new tags, making them sticky & commenting on Instagram
    new_tags = campaign.tags - self.tags
    new_tags.map do |tag|
      self.photo_tags << self.photo_tags.build(sticky: true, tag: tag)
    end

    text = "I added this photo to a competition on @#{AppConfig.instagram.account}. "
    text += new_tags.map{|t| "##{t.name}"}.join(" ")
    
    # Comment on Instagram, to tag this photo for real.
    # Don't bother in development, our token doesn't have permission.
    if self.user.access_token and !(Rails.env =~ /development/i)
      Star::Requester.post "media/#{self.uid}/comments",
        {access_token: self.user.access_token,
         text: text}.to_param
    end

    return self.tags(true)
  end
end
