# Public: An Instagram user.
#
# This user may have an access_token, or it may not. We create user models
# for every user we know about, even ones that have never visited Taggregator
# (e.g. ones we have heard about via the Instagram API).
#
# This allows us to immediately match a user up with their photos if they
# log in having already 'participated' passively in campaigns.
class User < ActiveRecord::Base
  include Extensions::Adminable

  attr_accessible :full_name, :access_token, :uid, :profile_picture, :username,
    :email, :last_signed_in_at, :can_receive_mail

  validates :uid, uniqueness: true
  validates :email, uniqueness: true, length: {minimum: 1}, allow_nil: true

  has_many :photos
  has_one :sponsor

  before_create :generate_verification_token
  after_save :enqueue_metrics_update

  # Scope to return authenticated users. That is, users that have logged in
  # at some point on Taggregator (because we have their access token).
  #
  # Just because we have their access token, doesn't mean we can do stuff on
  # their behalf. They might have revoked it, in which case we should delete
  # it.
  scope :authenticated, -> { where("access_token IS NOT NULL") }
  scope :emailable, -> { where("email IS NOT NULL and can_receive_mail = ?", true) }

  # Public: Get recent Instagram images for this user. Attempt to be
  # intelligent and only fetch new ones. We'll worry about pagination later?
  def recent_images(count = 20, page = 1)
    latest_photo = self.photos.limit(1).first
    min_id = if latest_photo
      latest_photo.uid
    else
      nil
    end

    params = {count: count, access_token: self.access_token}
    params[:min_id] = min_id if min_id

    response = Star::Requester.get "users/#{self.uid}/media/recent", params
    # Add new photos to DB
    response.body.data.each do |image| 
      Photo.create_or_update_from_instagram(image, self)
    end
    self.photos.order('created_at DESC').limit(count)

  end

  def profile_url
    "https://instagram.com/#{self.username}"
  end

  # Public: Update the user's metrics from Instagram
  def update_metrics
    params = {
      client_id: AppConfig.instagram.client_id
    }
    params[:access_token] = self.access_token if self.access_token
    response = Star::Requester.get "users/#{self.uid}", params
    if response.success? and response.body.data
      [:follows, :followed_by, :media].each do |field|
        self.send("#{field}=", response.body.data.counts[field])
      end
      [:username, :profile_picture, :full_name].each do |field|
        self.send("#{field}=", response.body.data[field])
      end
    else
      logger.warn "Tried to update metrics for #{self.uid} but failed: #{response.body}"
    end
  rescue Faraday::Error::ClientError => e
    logger.warn "User #{self.id} is possibly private/gone"
  ensure
    self.metrics_last_updated_at = Time.now
    self.save
  end

  # Override accessors for metrics to update metrics automatically as they are
  # accessed.
  [:follows, :followed_by, :media].each do |field|
    define_method field do |*args|
      enqueue_metrics_update
      super(*args)
    end
  end

  def need_to_update_metrics?
    !self.metrics_last_updated_at || self.metrics_last_updated_at < AppConfig.user_metrics_ttl.ago
  end

  # Private: Create a new user from an Omniauth hash.
  def self.create_with_omniauth(auth)
    create! do |user|
      user.full_name = auth.info.name
      user.access_token = auth.credentials.token
      user.uid = auth.uid
      user.profile_picture = auth.info.image
      user.username = auth.info.nickname
    end
  end

  # Private: Create a new user (with no credentials) from Instagram data
  def self.create_with_instagram(user_data)
    create! do |user|
      user.full_name = user_data.full_name
      user.uid = user_data.id
      user.profile_picture = user_data.profile_picture
      user.username = user_data.username
    end
  end

  # Public: Returns user's photos that have won campaigns.
  #
  #   since - How far back to look for finished campaigns that the user has
  #   won. Default is forever
  def winning_photos(since=Time.at(0))
    Photo.joins("INNER JOIN campaigns on campaigns.winning_photo_id = photos.id")
      .where("photos.user_id = ? AND campaigns.end_date > ?", self.id, since)
  end


  # Public: Returns all sorted by their star score.
  def self.star_score_leaderboard
    User.authenticated.sort_by{|u| -u.star_score}[0,10]
  end

  # Public: Returns a user leaderboard of [user, campaigns_won] pairs in an 
  # array of arrays.
  #
  # This could probably be implemented as a join, though as it stands it is 
  # only a couple of SQL queries thanks to eager loading.
  def self.leaderboard
    Campaign.includes(winning_photo: :user)
      .map{|c| c.winning_photo && c.winning_photo.user}
      .compact
      .each_with_object(Hash.new(0)){|o, h| h[o] += 1 }
      .map{|a| Hashie::Mash.new(user: a[0], campaigns_won: a[1])}
      .sort{|a,b| b.campaigns_won <=> a.campaigns_won}
  end

  def member?
    self.email.present? || self.access_token.present?
  end

  def is_sponsor?
    self.sponsor.present?
  end

  # Public: The StarScore of a user is a sum of all the scores in instances
  # where their photos have been part of a campaign.
  def star_score
    # I'm not sure if caching based on `self` is enough, because photos may
    # change without this user changing, so also use the current time (to the
    # nearest hour) to help.
    Rails.cache.fetch([self, "score", Time.now.strftime("%Y%m%d%H")]) do
      CampaignPhoto.select(:score)
        .joins(:photo => :user)
        .where(:users => {id: id}, :campaign_photos => {:approved => true})
        .to_a
        .inject(0){|acc, cp| acc + cp.score}
    end
  end

  # Internal: Sidekiq job for updating user metrics
  class MetricsJob
    include Sidekiq::Worker
    sidekiq_options :unique => true

    def perform(user_id)
      begin
        user = User.find(user_id)
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.warn "User has gone away? #{user_id}"
      else
        # Double check we still need to do this
        user.update_metrics if user.need_to_update_metrics?
      end
    end

  end

  private
  def generate_verification_token
    self.verification_token = SecureRandom.hex
  end

  # Internal: Enqueue a metrics update for the user if their metrics haven't
  # been updated 'recently' (defined in config)
  def enqueue_metrics_update
    User::MetricsJob.perform_async(self.id) if self.need_to_update_metrics?
  end


end
