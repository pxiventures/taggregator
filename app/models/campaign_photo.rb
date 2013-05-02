class CampaignPhoto < ActiveRecord::Base
  attr_accessible :campaign_id, :photo_id, :score, :campaign, :photo,
    :moderated, :approved

  belongs_to :campaign, autosave: true
  belongs_to :photo, autosave: true

  validates :campaign_id, uniqueness: {scope: :photo_id}

  validates :campaign_id, presence: true
  validates :photo_id, presence: true

  before_create :set_approved_state_from_campaign

  after_save :update_score
  after_touch :update_score

  scope :approved, -> { where("approved = true") }

  def update_score
    # Update the score if the campaign hasn't ended (or we don't have a score
    # at all yet).
    self.update_column(:score, photo.score(campaign)) if !self.score || self.campaign.end_date > Time.now
  end

  private
  def set_approved_state_from_campaign
    self.approved = self.campaign.default_approved_state if self.approved.nil?
    # Assignment could return false which triggers 'RecordNotSaved'
    true
  end
end
