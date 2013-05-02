require 'spec_helper'

describe "Logged in UI" do 

  before :each do
    stub_requester
    @admin_user = FactoryGirl.create :admin_user
    @user = FactoryGirl.create :authenticated_user
    mock_omniauth(@user.uid)
    visit root_path
    click_link "start"
  end

  it "should not show a link to the admin dashboard" do
    page.should_not have_link("Dashboard")
  end


end
