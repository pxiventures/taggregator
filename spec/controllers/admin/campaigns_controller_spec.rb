require 'spec_helper'

describe Admin::CampaignsController do
  render_views

  before do
    Tag.any_instance.stub(:get_recent_media)
    stub_requester
    @admin = FactoryGirl.create :user, admin: true
    session[:user_id] = @admin.id
    @campaign = FactoryGirl.create :campaign
  end

  it "should require admin access" do
    session[:user_id] = nil
    get :index
    response.should redirect_to(root_url)
  end

  it "show action should render show template" do
    get :show, :id => @campaign.id
    response.should render_template(:show)
  end

  it "new action should render new template" do
    get :new
    response.should render_template(:new)
  end

  it "create action should render new template when model is invalid" do
    Campaign.any_instance.stub(:valid?).and_return(false)
    post :create
    response.should render_template(:new)
  end

  it "create action should redirect when model is valid" do
    Campaign.any_instance.stub(:valid?).and_return(true)
    post :create
    response.should redirect_to(admin_campaign_url(assigns[:campaign]))
  end

  it "edit action should render edit template" do
    get :edit, :id => @campaign.id
    response.should render_template(:edit)
  end

  describe "#set_winning_photo" do

    before do
      # Stub out update_metrics to stop it screwing with the test data
      Photo.any_instance.stub(:update_metrics).and_return(true)
      @winner = FactoryGirl.create :authenticated_user
      @losers = 3.times.map{FactoryGirl.create :authenticated_user}

      @winning_photo = FactoryGirl.create :photo, user: @winner, likes: 3000, metrics_last_updated_at: Time.now
      @winning_photo.add_to_campaign(@campaign)

      @losers.each do |loser|
        p = FactoryGirl.create :photo, user: loser, likes: 1
        p.add_to_campaign(@campaign)
      end
    end

    it "should set the winning photo for the campaign" do
      expect {
        post :set_winning_photo, id: @campaign.id
      }.to change{Campaign.find(@campaign.id).winning_photo}.from(nil).to(@winning_photo)
    end

  end

  it "update action should render edit template when model is invalid" do
    Campaign.any_instance.stub(:valid?).and_return(false)
    put :update, :id => @campaign.id
    response.should render_template(:edit)
  end

  it "update action should redirect when model is valid" do
    Campaign.any_instance.stub(:valid?).and_return(true)
    put :update, :id => @campaign.id
    response.should redirect_to(admin_campaign_url(assigns[:campaign]))
  end

  it "destroy action should destroy model and redirect to index action" do
    campaign = @campaign
    delete :destroy, :id => campaign
    response.should redirect_to(admin_root_url)
    Campaign.exists?(campaign.id).should be_false
  end

  describe "as a sponsor" do
    before do
      @sponsor_user = FactoryGirl.create :sponsor_user
      session[:user_id] = @sponsor_user.id
    end
    
    it "should not let the user view other campaigns" do
      get :show, :id => @campaign.id
      response.should redirect_to(admin_root_url)
    end

    describe "#create" do
      it "should create a campaign associated with this sponsor" do
        expect {
          Campaign.any_instance.stub(:valid?).and_return(true)
          post :create
        }.to change{ @sponsor_user.sponsor.reload.campaigns.count }.from(0).to(1)
      end
    end

  end


end
