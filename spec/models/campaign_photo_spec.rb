require 'spec_helper'

describe CampaignPhoto do

  before do
    stub_requester
  end

  it "should update the score when a photo's metrics updates when the photo is already part of a campaign" do
    @photo = FactoryGirl.create :photo, metrics_last_updated_at: Time.now
    @campaign = FactoryGirl.create :campaign

    @photo.tags = @campaign.tags
    campaign_photo = @photo.campaign_photos(true).first
    # Cache invalidation
    sleep 1

    expect{
      @photo.likes += 100
      @photo.save!
    }.to change{campaign_photo.score}
  end

end
