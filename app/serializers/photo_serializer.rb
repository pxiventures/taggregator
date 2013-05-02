class PhotoSerializer < ActiveModel::Serializer
  attributes :id, :uid, :url, :image_url, :thumbnail_url, :created_at, :updated_at, :comments, :likes, :caption, :score

  # Needs more detail.
  has_many :campaigns
  has_one :user

  def campaigns
    object.campaigns.where("start_date <= ?", Time.now)
  end

  def score
    object.score(@options[:campaign_to_score] || nil)
  end
end
