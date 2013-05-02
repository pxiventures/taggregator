require 'spec_helper'

describe Admin::RootController do
  render_views

  before do
    stub_requester
  end

  describe "as an admin" do
    before do
      @admin = FactoryGirl.create :user, admin: true
      session[:user_id] = @admin.id
    end

    describe "#daily_email" do

      before do
        @emailable_users = 3.times.map{ FactoryGirl.create :authenticated_user }
      end

      it "should enqueue a daily email job for every emailable user" do
        post :daily_email
        Sidekiq::Extensions::DelayedMailer.jobs.size.should eq(@emailable_users.length)
      end

      it "should record that the emails were sent in the db" do
        expect {
          post :daily_email
        }.to change {DailyEmail.count}.from(0).to(1)

        DailyEmail.first.emails_sent.should eq(@emailable_users.length)
        DailyEmail.first.sent_at.should > 1.minute.ago
      end

      it "should notify the admin" do
        post :daily_email
        flash[:notice].should include("Sending")
      end

    end
  end
end

