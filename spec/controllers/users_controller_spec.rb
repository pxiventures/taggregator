require 'spec_helper'

describe UsersController do
  render_views

  before do
    stub_requester
    @user = FactoryGirl.create :authenticated_user
    session[:user_id] = @user.id
    @photo = FactoryGirl.create :photo
  end

  describe "#like" do
    it "should like a photo" do
      Star::Requester.should_receive(:post)
        .with("media/#{@photo.uid}/likes", "access_token=#{@user.access_token}")
        .and_return(double("response", headers: {}, body: ""))
      post :like, uid: @photo.uid
    end

    it "should enqueue a known photo for updates" do
      Photo.any_instance.should_receive(:queue_for_updates)
      post :like, uid: @photo.uid
    end

  end

  describe "#verify" do
    it "should not work if the user is not logged in" do
      session[:user_id] = nil
      get :verify
      response.should_not be_success
    end

    it "should work if the user is logged in" do
      get :verify
      response.content_type.should == "application/json"
    end
  end
end
