require 'spec_helper'

describe "Admin UI" do

  before :each do
    stub_requester
    @admin = FactoryGirl.create :admin_user
    mock_omniauth(@admin.uid)
  end

  describe "The admin page" do
    before do
      visit root_path
      click_link "start"
      within(".nav") do
        click_link "Dashboard"
      end
    end

    it "should show when the last daily email was sent" do
      DailyEmail.destroy_all
      FactoryGirl.create :daily_email, sent_at: 1.day.ago, emails_sent: 3
      visit admin_root_path
      page.should have_text "Daily email was last sent 1 day ago. 3 emails were sent."
    end

    it "should show the quick add form" do
      page.should have_text "Quick Add"
    end

    it "should show links to send the email and update metrics" do
      page.should have_link "Send daily email"
      page.should have_link "Update metrics for active photos"
    end

    describe "with a campaign" do
      before do
        @campaign = FactoryGirl.create :campaign
        # Reload the page
        visit current_path
      end

      it "should have links to different forms of 'view'" do
        page.should have_link "Public"
        page.should have_link "Admin"
        page.should have_link "Embed"
      end
    end

  end
end
