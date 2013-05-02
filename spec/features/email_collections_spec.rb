require 'spec_helper'

describe "EmailCollections" do

  before :each do
    stub_requester
    @user = FactoryGirl.create :user
    mock_omniauth(@user.uid)
  end

  it "requires a new user to enter their email address before giving access" do
    my_email = "john@doe.com"
    visit root_path
    click_link "start"
    page.should have_text "Enter your email address"
    within("#email-form") do
      fill_in("email", with: my_email)
      click_button "Submit"
    end
    User.find(@user.id).email.should == my_email
  end

  it "un-verifies a user if they have previously been verified then provide a new email address" do
    @user = FactoryGirl.create :authenticated_user
    mock_omniauth(@user.uid)
    visit root_path
    click_link "start"
    visit email_path
    within("#email-form") do
      fill_in("email", with: "new@email.com")
      click_button "Submit"
    end
    User.find(@user.id).email.should == "new@email.com"
    User.find(@user.id).verified.should be_false
  end

  it "warns the user they have already provided their email address if they access the page again" do
    @user.email = "john@doe.com"
    @user.save
    visit root_path
    click_link "start"
    visit email_path
    page.should have_text "You have already supplied"
  end

  it "verifies a user when they click the link in their email" do
    @user.verification_token = token = "example"
    @user.save
    visit root_path
    click_link "start"
    visit verify_email_path(t: token)
    User.find(@user.id).verified.should be_true
  end
end
