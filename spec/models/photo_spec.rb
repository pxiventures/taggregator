require 'spec_helper'

describe Photo do

  before do
    stub_requester
    @instagram_data = InstagramResponses.photo.data
  end

  it "is valid" do
    photo = FactoryGirl.build :photo
    expect(photo.valid?).to be_true
  end

  describe "#campaigns" do

    before do
      stub_requester
      @photo = FactoryGirl.create :photo, metrics_last_updated_at: Time.now
      @campaign = FactoryGirl.create :campaign
    end

    it "should include the campaign that a photo has corresponding tags for" do
      @photo.tags = @campaign.tags
      @photo.reload.campaigns.should include(@campaign)
      @photo.campaigns.length.should == 1
    end

  end

  describe "#approved_campaigns" do
    it "should not include a photo that is not approved" do
      @photo = FactoryGirl.create :photo, metrics_last_updated_at: Time.now
      join = FactoryGirl.create :campaign_photo,
        photo: @photo,
        approved: false
      @photo.reload.approved_campaigns.should_not include(join.campaign)
    end
  end

  describe "#queue_for_updates" do

    it "should enqueue photo updater" do
      @photo = FactoryGirl.create :photo
      @photo.metrics_last_updated_at = nil
      Star::PhotoUpdater::Updater.should_receive(:perform_async)
        .with(@photo.id, false)
      @photo.queue_for_updates
    end

  end

  describe "#create_from_instagram" do

    it "saves a new photo" do
      lambda {
        Photo.create_from_instagram(@instagram_data)
      }.should change{Photo.count}.by(1)
    end

    it "associates a new photo with a user when supplied one" do
      user = FactoryGirl.create :user
      photo = Photo.create_from_instagram(@instagram_data, user)
      Photo.find(photo.id).user.should == user
    end

    it "queues a Resque job" do
      photo = Photo.create_from_instagram(@instagram_data)
      Star::PhotoUpdater::Updater.should have_queued_job(photo.id)
    end

    it "creates tags that correspond to the photo's tags" do
      photo = Photo.create_from_instagram(@instagram_data)
      (photo.tags.pluck(:name) - @instagram_data.tags).should be_empty
    end

    it "should delete tags that are not in the Instagram data" do
      photo = Photo.create_from_instagram(@instagram_data)
      tag = FactoryGirl.create :tag
      photo.tags << tag
      (photo.tags.pluck(:name) - @instagram_data.tags).should include(tag.name)
      photo = Photo.create_from_instagram(@instagram_data)
      (photo.tags.pluck(:name) - @instagram_data.tags).should be_empty
    end

    it "should not delete sticky tags even if they aren't in the Instagram data" do
      photo = Photo.create_from_instagram @instagram_data
      photo_tag = FactoryGirl.create :photo_tag, photo: photo, sticky: true
      photo.photo_tags << photo_tag
      photo = Photo.create_from_instagram @instagram_data
      (photo.tags.pluck(:name) - @instagram_data.tags).should include(photo_tag.tag.name)
    end


  end

  describe "#score" do

    it "returns a float value" do
      photo = FactoryGirl.build :photo, created_at: Time.now
      photo.score.should be_a(Float)
    end

  end

  describe "#add_to_campaign" do
    before do
      stub_requester
      @photo = FactoryGirl.create :photo, user: FactoryGirl.create(:authenticated_user), metrics_last_updated_at: Time.now
      @campaign = FactoryGirl.create :campaign
    end

    it "should cause the photo to show up in Campaign#photos" do
      @photo.add_to_campaign(@campaign)
      @campaign.reload.photos.should include(@photo)
      @photo.tags.should =~ @campaign.tags
    end

    it "should comment on the photo with the new tags" do
      comment_text = "I added this photo to a competition on @#{AppConfig.instagram.account}. #{@campaign.tags.map{|t| "##{t.name}"}.join(" ")}"
      Star::Requester.should_receive(:post).with(
        "media/#{@photo.uid}/comments",
        {
          access_token: @photo.user.access_token,
          text: comment_text
        }.to_param).once
      @photo.add_to_campaign(@campaign)
    end

    it "should only comment with tags the photo isn't already commented with" do
      @photo.tags << @campaign.tags.first
      comment_text = "I added this photo to a competition on @#{AppConfig.instagram.account}. " + (@campaign.tags - [@campaign.tags.first]).map{|t| "##{t.name}"}.join(" ")
      Star::Requester.should_receive(:post).with(
        "media/#{@photo.uid}/comments",
        {
          access_token: @photo.user.access_token,
          text: comment_text
        }.to_param)
      @photo.add_to_campaign(@campaign)
      @photo.tags.should =~ @campaign.tags
    end

    it "should create sticky photo tags" do
      @photo.add_to_campaign(@campaign)
      @photo.photo_tags.each do |pt|
        pt.sticky.should == true
      end
    end

    it "should do nothing if the photo is already in the campaign" do
      @photo.add_to_campaign(@campaign)
      @photo.errors.should be_empty

      @photo.reload.add_to_campaign(@campaign).should be_false
      @photo.errors.should_not be_empty
    end

    it "should do nothing if the photo was moderated out of the campaign" do
      @photo.add_to_campaign(@campaign)
      join = @photo.campaign_photos.where(campaign_id: @campaign.id).first
      join.moderated = true
      join.approved = false
      join.save

      @photo.add_to_campaign(@campaign)
      @photo.errors.should_not be_empty
      @photo.errors.full_messages.join.should include("not approved")
    end
  end

  describe "#update_metrics" do

    before do
      stub_requester
      @photo = FactoryGirl.create :photo, comments: 0, likes: 0, metrics_last_updated_at: Time.now-1.second
    end

    it "should update the photo's comment count" do
      expect {
        @photo.update_metrics
      }.to change{@photo["comments"]}.from(0).to(InstagramResponses.photo.data.comments["count"])
    end

    it "should update the photo's like count" do
      expect {
        @photo.update_metrics
      }.to change{@photo["likes"]}.from(0).to(InstagramResponses.photo.data.likes["count"])
    end

    it "should update the metrics_last_updated_at attribute" do
      expect {
        @photo.update_metrics
      }.to change{@photo.metrics_last_updated_at}
    end

    
  end

  describe "formatted as JSON" do
    before do
      @photo = FactoryGirl.create :photo
      @campaign = FactoryGirl.create :campaign
      @photo.campaigns << @campaign
    end

    it "should include the campaign" do
      JSON.parse(json_for(@photo))["campaigns"].any?{|c| c["id"] == @campaign.id}.should be
    end

    it "should not include campaigns that haven't started" do
      @campaign.update_attribute(:start_date, Time.now+1.day)
      JSON.parse(json_for(@photo.reload))["campaigns"].should be_empty
    end

  end

end
