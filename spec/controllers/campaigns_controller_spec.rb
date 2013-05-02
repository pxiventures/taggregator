require 'spec_helper'

describe CampaignsController do
  render_views

  before do
    stub_requester
    Photo.any_instance.stub(:update_metrics).and_return(true)
    @campaign = FactoryGirl.create :campaign
  end

  describe "#top_photos" do
    it "should not include a sponsored campaign" do
      sponsored_campaign = FactoryGirl.create :sponsored_campaign
      get :top_photos
      assigns(:campaigns).should_not include(sponsored_campaign)
    end
  end

  describe "#leaderboard" do
    it "should work even if the campaign has less than 10 photos" do
      5.times do 
        photo = FactoryGirl.create :photo
        photo.add_to_campaign @campaign
      end

      get :leaderboard, id: @campaign.id
      response.body.should_not == "[]"
    end

    it "shouldn't show unapproved photos" do
      campaign_photo = FactoryGirl.create :campaign_photo,
        campaign: @campaign,
        approved: false

      get :leaderboard, id: @campaign.id
      response.body.should eq("[]")
    end

  end
        

end
