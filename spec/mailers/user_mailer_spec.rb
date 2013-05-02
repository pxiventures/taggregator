require "spec_helper"

describe UserMailer do

  before do
    stub_requester
    @user = FactoryGirl.create :authenticated_user
  end

  describe "verify_email" do
    let(:mail) { UserMailer.verify_email(@user) }

    it "renders the headers" do
      mail.subject.should include("Please verify your email address")
      mail.to.should eq([@user.email])
      mail.from.should eq([AppConfig.email.from])
    end

    it "renders the body" do
      mail.body.encoded.should match("click the link")
    end
  end

end
