require 'spec_helper'

describe User do

  before do
    stub_requester
    # User model is going to try and update metrics.
    @user = FactoryGirl.create(:user)
  end

  it "should have a verification token after creation" do
    @user.verification_token.should_not be nil
  end

  it "should queue a Resque job when saved" do
    @user.metrics_last_updated_at = Time.at(0)
    @user.save
    User::MetricsJob.should have_queued_job(@user.id)
  end

  it "#authenticated scope should return only authenticated users" do
    expect {
      authenticated_user = FactoryGirl.create(:authenticated_user)
      User.authenticated.should include(authenticated_user)   # Ssh.
    }.to change{ User.authenticated.count}.from(0).to(1)
    User.authenticated.should_not include(@user)
  end

  describe "#update_metrics" do

    before do
      @user = FactoryGirl.create(:user)
    end

    it "should alter the 3 metrics" do
      stub_requester
      @user.update_metrics
      [:follows, :followed_by, :media].each do |field|
        @user[field].should == InstagramResponses.user.data.counts[field]
      end
    end

  end

  describe "#enqueue_metrics_update" do

    before do
      @user = FactoryGirl.create(:user)
    end
    
    it "should not enqueue a job if the metrics have been updated_recently" do
      @user.metrics_last_updated_at = Time.now
      @user.save
      User::MetricsJob.should_not have_queued_job
    end
  end

  describe "#star_score" do

    before do
      @photos = 3.times.map{FactoryGirl.create :photo, user: @user, likes: (rand * 6).ceil}
      @photos.each{|photo| FactoryGirl.create :campaign_photo, photo: photo}
    end

    it "should be a sum of photo star score" do
      # Float laziness
      @user.star_score.should eq(@photos.inject(0){|acc, x| acc + x.score.round(2)})
    end

    it "should not take into account unapproved photos" do
      current_star_score = @user.star_score
      @photos.first.reload.campaign_photos.first.update_attributes(approved: false)
      @user.reload.star_score.should_not eq(current_star_score)
    end
  end

end
