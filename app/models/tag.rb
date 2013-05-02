class Tag < ActiveRecord::Base
  attr_accessible :name, :campaign_tag, :photo_tag

  has_many :campaign_tags, dependent: :destroy
  has_many :photo_tags, dependent: :destroy
  has_many :campaigns, through: :campaign_tags
  has_many :photos, through: :photo_tags

  validates :name, presence: true, uniqueness: true

  # Public: Get some recent media for this tag.
  # DO NOT set this as a hook, you will cause potentially infinite recursion.
  def get_recent_media
    response = Star::Requester.get "tags/#{self.name}/media/recent", client_id: AppConfig.instagram.client_id
    if response.success?
      response.body.data.each do |photo|
        Photo.create_or_update_from_instagram(photo)
      end
    end
  end
end
