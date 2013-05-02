require 'spec_helper'

describe "Being a sponsor" do

  before :each do
    stub_requester
    # Create an admin user to be the 'first' user.
    @admin_user = FactoryGirl.create :admin_user
    @sponsor_user = FactoryGirl.create :sponsor_user
    mock_omniauth(@sponsor_user.uid)
    visit root_path
    click_link "start"
  end

  describe "The home page" do
    it "should show the 'Dashboard' link" do
      page.should have_link "Dashboard"
    end
  end

  describe "The dashboard" do
    before :each do
      within(".nav") do
        click_link "Dashboard"
      end
    end

    it "should have a 'new campaign' link" do
      page.should have_link "New campaign"
    end

    it "should not show the Quick Add form" do
      page.should_not have_text "Quick Add"
    end

    it "should not show the links to send the daily email or update metrics" do
      page.should_not have_link "Send daily email"
      page.should_not have_link "Update metrics for active photos"
    end

    it "should not show a link to Rails Admin" do
      page.should_not have_link "Rails Admin"
    end

    describe "with a campaign" do
      before do
        @campaign = FactoryGirl.create :campaign, sponsor: @sponsor_user.sponsor
        # Reload the page
        visit current_path
      end

      it "should show the user's campaign" do
        page.should have_text @campaign.name
      end

      it "should not show other campaigns" do
        @other_campaign = FactoryGirl.create :campaign
        # Reload
        visit current_path
        page.should_not have_text @other_campaign.name
      end
      
      it "should not show when the daily email was last sent" do
        FactoryGirl.create :daily_email
        visit current_path
        page.should_not have_text "Daily email"
      end

    end

  end
end
