require 'spec_helper'

describe DailyEmail do

  before do
    stub_requester
    DailyEmail.destroy_all
    @running_campaigns =  3.times.map {FactoryGirl.create :campaign}
    @winning_photo = FactoryGirl.create :photo
    @ended_campaign = FactoryGirl.create :campaign,
      end_date: 1.day.ago,
      start_date: 2.days.ago,
      winning_photo: @winning_photo
  end

  describe "self#can_send?" do

    it "Returns true if the system is in a 'valid' state" do
      DailyEmail.can_send?.should be_true
    end

    it "Returns false if a winning photo hasn't been recorded for an ended campaign" do
      @ended_campaign.winning_photo = nil
      @ended_campaign.save
      DailyEmail.can_send?.should be_false
    end

    it "Returns false if there aren't 3 campaigns" do
      @running_campaigns.first.destroy
      DailyEmail.can_send?.should be_false
    end

    it "Returns false if there are 3 campaigns, but one of them is sponsored" do
      @running_campaigns.first.sponsor = FactoryGirl.create :sponsor
      @running_campaigns.first.save
      DailyEmail.can_send?.should be_false
    end

    it "Returns true even if there is an ended sponsored campaign where the winning photo hasn't been recorded" do
      FactoryGirl.create :sponsored_campaign,
        winning_photo_id: nil,
        start_date: 2.days.ago,
        end_date: 1.day.ago
      DailyEmail.can_send?.should be_true
    end

  end

  describe "self#should_send?" do

    it "should return true if there's no previous daily emails" do
      DailyEmail.should_send?.should be_true
    end

    it "should return false if the last daily email was < 24 hours ago" do
      FactoryGirl.create :daily_email, sent_at: 6.hours.ago
      DailyEmail.should_send?.should be_false
    end

    it "should return true if the last daily email was > 24 hours ago" do
      FactoryGirl.create :daily_email, sent_at: 25.hours.ago
      DailyEmail.should_send?.should be_true
    end

  end

end
