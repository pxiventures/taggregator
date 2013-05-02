class CampaignTag < ActiveRecord::Base
  attr_accessible :campaign, :tag, :campaign_id, :tag_id

  belongs_to :campaign, touch: true
  belongs_to :tag
end
