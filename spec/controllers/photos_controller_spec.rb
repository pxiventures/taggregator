require 'spec_helper'

describe PhotosController do
  render_views

  before do
    stub_requester
  end

  it "should require authorization" do
    get :index
    response.should redirect_to(root_url)
    flash[:alert].should include("You need")
  end

  describe "When logged in" do
    before do
      @user = FactoryGirl.create :authenticated_user
      session[:user_id] = @user.id
    end

    it "should not add a sponsored campaign to the @campaigns" do
      @sponsored_campaign = FactoryGirl.create :sponsored_campaign
      get :index
      assigns(:campaigns).should_not include(@sponsored_campaign)
    end

    it "should not include ended sponsored campaigns in @ended_campaigns" do
      @winning_photo = FactoryGirl.create :photo
      @ended_campaign = FactoryGirl.create :sponsored_campaign,
        start_date: 3.days.ago,
        end_date: 2.days.ago,
        winning_photo_id: @winning_photo.id
      get :index
      assigns(:ended_campaigns).should_not include(@ended_campaign)
    end
  end

end
