require "spec_helper"

describe CampaignMailer do
  before do
    stub_requester
    @campaign = FactoryGirl.create :campaign
    @ended_sponsored_campaign = FactoryGirl.create :sponsored_campaign,
      start_date: 2.days.ago,
      end_date: 1.day.ago,
      winning_photo_id: FactoryGirl.create(:photo).id
    @running_sponsored_campaign = FactoryGirl.create :sponsored_campaign
    @user = FactoryGirl.create :authenticated_user

    @photo_in_sponsored_campaign = FactoryGirl.create :photo,
      user: @user,
      created_at: 36.hours.ago
    @photo_in_sponsored_campaign.add_to_campaign(@ended_sponsored_campaign)
  end

  describe "daily_email" do

    let(:mail) { CampaignMailer.daily_email(@user) }

    it "renders the headers" do
      mail.to.should eq([@user.email])
      mail.from.should eq([AppConfig.email.from])
    end

    it "renders the body" do
      mail.body.encoded.should match("These were the winning photos for the day")
    end

    it "should not render a finished sponsored campaign" do
      mail.body.encoded.should_not match(@ended_sponsored_campaign.name)
    end

    it "should not render a running sponsored campaign" do
      mail.body.encoded.should_not match(@running_sponsored_campaign.name)
    end

    it "should not render the user's submission to an ended sponsored campaign" do
      mail.body.encoded.should_not match(@photo_in_sponsored_campaign.caption)
    end

  end

end
