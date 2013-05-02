# Public: A Campaign, or 'competition' is Taggregator-defined and all photos 
# in it are elligible for the competition. A campaign can have many tags
# (e.g. a campaign for 'Snowy London' might have the tags #snow, #london, and
# #taggregator), and photos are only part of a campaign if they are tagged with
# _all_ the campaign tags. This is so we can use collative tags like
# #taggregator, but might be something we outgrow.
#
# Campaigns/competitions also have a start date, end date and a record of
# whether an email was sent at the start + end of the campaign. They also have
# a reference to the winning photo.
class Campaign < ActiveRecord::Base
  attr_accessible :name, :start_date, :end_date, :tag_tokens,
    :default_approved_state

  validates :name, presence: true
  validates :start_date, :end_date, presence: true

  validate :start_date_must_be_before_end_date

  has_many :campaign_tags, dependent: :delete_all
  has_many :tags, through: :campaign_tags

  has_many :campaign_photos, dependent: :delete_all
  has_many :photos, through: :campaign_photos
  # This is the same join table, just a different name with a condition.
  has_many :approved_photos,
    through: :campaign_photos,
    source: :photo,
    class_name: Photo,
    conditions: {
      campaign_photos: {
        approved: true
      }
    }

  belongs_to :winning_photo, class_name: Photo, inverse_of: :won_campaign

  belongs_to :sponsor

  scope :not_sponsored, -> { where("sponsor_id is NULL") }
  scope :running, -> { where("start_date <= ? and end_date >= ?", Time.now, Time.now) }
  scope :ended_with_winner, -> { where("winning_photo_id IS NOT NULL").order("end_date DESC") }

  before_save :set_default_approved_state_on_existing_photos

  # Public: Fairly self-explanatory. A campaign has ended if the winning
  # photo has been marked.
  def ended?
    winning_photo.present?
  end

  def started?; start_date <= Time.now; end

  # Public: Get the next 'start date' for a campaign. Used for quickly adding
  # a campaign in the admin panel.
  def self.next_start_date
    (Campaign.order("start_date DESC").first.start_date + 1.day).midnight + 10.hours
  end

  # Public: I can't guarantee that this is a good idea.
  #
  # only_emails: Only return participating users we have email addresses for.
  # distinct: Only return unique results, defaults to true.
  def participating_users(only_emails=false, distinct=true)
    condition = "campaigns.id = #{self.id} and campaign_photos.approved = true"
    condition += " AND users.email IS NOT NULL" if only_emails
    result = User.joins(photos: {campaign_photos: :campaign}).where(condition)
    result = result.uniq if distinct
    return result
  end

  # Internal: Translate input from form (which is comma separated) into array for
  # relational assignment.
  def tag_tokens=(ids)
    self.tag_ids = ids.split(",").map(&:to_i)
  end

  def self.quick_add(name, tag_name)
    campaign = new do |c|
      c.name = name
      c.start_date = next_start_date
      c.end_date = c.start_date + AppConfig.default_campaign_length
    end

    tag = Tag.where(name: tag_name).first_or_create
    default_tag = Tag.where(name: AppConfig.default_hashtag).first_or_create
    campaign.tag_ids = [tag.id, default_tag.id]

    campaign.save!
    campaign
  end

  # Internal: Find all photos that meet the criteria to belong to this campaign
  # (tagged with all the campaign tags) and construct join models to link them
  # together.
  def join_to_photos
    # Inverse of #join_to_campaigns
    # Source: http://stackoverflow.com/questions/8425232/sql-select-all-rows-where-subset-exists
    photos_in_campaign = Photo.joins(:photo_tags)
      .select("photos.*, COUNT(photos.id)")
      .where(
        "photo_tags.tag_id IN (:tags) AND photos.created_at < :end_date",
        {tags: self.tags(true),
         end_date: self.end_date})
      .group("photos.id")
      .having("COUNT(photos.id) = #{self.campaign_tags(true).length}")

    self.photos = photos_in_campaign
  end

  # Public: Define both ranked_photos and ranked_approved_photos. You should
  # probably be using the latter.
  %w(photos approved_photos).each do |photo_scope|
    define_method "ranked_#{photo_scope}" do
      self.send(photo_scope).order("campaign_photos.score DESC, id")
    end
  end

  # Deprecated and now you really shouldn't use this 'cos of moderation.
  def photos_count
    self.photos.count
  end

  # Public: Return the top photo.
  def top_photo
    self.ranked_photos.first
  end

  private
  def start_date_must_be_before_end_date
    unless self.start_date < self.end_date
      self.errors.add(:start_date, "must be before end date")
    end
  end

  def set_default_approved_state_on_existing_photos
    if self.default_approved_state_changed?
      campaign_photos.where(moderated: false).update_all(approved: self.default_approved_state)
    end
  end
end
