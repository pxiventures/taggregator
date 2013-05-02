require 'spec_helper'

describe Campaign do

  before do
    stub_requester
    Tag.any_instance.stub(:get_recent_media)
    @campaign = FactoryGirl.create :campaign
  end

  describe "#participating_users" do

    before do
      @photos = 3.times.map{ photo = FactoryGirl.create(:photo); photo.tags << @campaign.tags; photo }
    end

    it "returns users that have photos in the campaign" do
      expect(@campaign.participating_users.length).to eq(@photos.length)
      expect(@campaign.participating_users - @photos.map{|p| p.user}).to be_empty
    end

    it "Doesn't return users without email address when only_emails is true" do
      @photos.first.user.update_attributes(email: nil)
      expect(@campaign.participating_users(true)).to_not include(@photos.first.user)
    end

    it "Doesn't return users that took a photo that has been moderated (and rejected)" do
      CampaignPhoto.where(photo_id: @photos.first.id, campaign_id: @campaign.id)
        .first
        .update_attributes(moderated: true, approved: false)
      expect(@campaign.participating_users(true)).to_not include(@photos.first.user)
    end

    it "Returns users that have 1 approved & 1 unapproved photo" do
      @user = FactoryGirl.create :user
      approved_photo = FactoryGirl.create :photo, user: @user
      FactoryGirl.create :campaign_photo,
        photo: approved_photo,
        campaign: @campaign,
        moderated: true,
        approved: true

      unapproved_photo = FactoryGirl.create :photo, user: @user
      FactoryGirl.create :campaign_photo,
        photo: unapproved_photo,
        campaign: @campaign,
        moderated: true,
        approved: false

      @campaign.reload.participating_users.should include(@user)
      
    end

  end

  describe "#photos and #photos_count" do
    before do
      @photos = 3.times.map{ photo = FactoryGirl.create(:photo); photo.tags = @campaign.tags; photo }
      @photos_not_quite_in_campaign = 3.times.map{|i| photo = FactoryGirl.create(:photo); photo.tags << @campaign.tags[i % @campaign.tags.length]; photo}
      @photos_not_in_campaign = 3.times.map{ photo = FactoryGirl.create(:photo) }
    end

    it "should return photos in the campaign and nothing else" do
      @campaign.photos(true).should =~ @photos
    end

    it "should return the right count" do
      @campaign.photos_count.should eq(@photos.length)
    end
  end

  describe "#tag_tokens=" do
    it "should split tag ids" do
      Campaign.any_instance.should_receive(:tag_ids=).with([1,2,3])
      @campaign.tag_tokens = "1,2,3"
    end
  end

  describe "#running" do
    it "returns an active campaign" do
      campaign = FactoryGirl.create :campaign, start_date: Time.now - 1.day, end_date: Time.now + 1.day
      expect(Campaign.running).to include(campaign)
    end

    it "doesn't return finished/inactive campaigns" do
      old_campaign = FactoryGirl.create :campaign, start_date: Time.now - 2.days, end_date: Time.now - 1.day
      too_new_campaign = FactoryGirl.create :campaign, start_date: Time.now + 1.day, end_date: Time.now + 2.days
      expect(Campaign.running).to_not include(old_campaign)
      expect(Campaign.running).to_not include(too_new_campaign)
    end
  end

  it "cannot have a start date greater than an end date" do
    invalid_campaign = FactoryGirl.build :campaign, start_date: Time.now + 1.day, end_date: Time.now - 1.day
    expect(invalid_campaign.valid?).to be_false
  end

  describe "#top_photo" do
    before do
      @campaign = FactoryGirl.create :campaign
      @photo = FactoryGirl.create :photo
      @photo.add_to_campaign @campaign
    end

    it "doesn't return an unapproved photo as the top photo" do
      join = FactoryGirl.create :campaign_photo,
        campaign: @campaign,
        approved: false
      @campaign.top_photo.should_not eq(join.photo)
    end
  end
end
