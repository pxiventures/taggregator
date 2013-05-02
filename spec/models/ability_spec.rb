require 'cancan/matchers'

describe "User" do
  describe "abilities" do
    subject { ability }
    let(:ability){ Ability.new(user) }
    let(:user){ nil }

    context "when is no one" do
      it { should_not be_able_to(:manage, Campaign) }
      it { should_not be_able_to(:update, Photo) }
    end

    context "When an ordinary user" do
      let(:user){ FactoryGirl.create :user }
      
      it { should_not be_able_to(:manage, Campaign) }
      it { should_not be_able_to(:update, Photo) }
    end

    context "When a sponsor" do
      let(:user){ FactoryGirl.create :sponsor_user }

      it "should not be able to manage other people's campaigns" do
        campaign = FactoryGirl.create :sponsored_campaign

        should_not be_able_to(:update, campaign)
      end

      it "should be able to update its campaign" do
        campaign = FactoryGirl.create :sponsored_campaign, sponsor: user.sponsor

        should be_able_to(:update, campaign)
      end

      it { should be_able_to(:create, Campaign) }

      it "should not be able to update an unassociated CampaignPhoto" do
        campaign_photo = FactoryGirl.create :campaign_photo

        should_not be_able_to(:update, campaign_photo)
      end

      it "should be able to update a CampaignPhoto in one of its campaigns" do
        campaign = FactoryGirl.create :sponsored_campaign, sponsor: user.sponsor
        campaign_photo = FactoryGirl.create :campaign_photo, campaign: campaign

        should be_able_to(:update, campaign_photo)
      end
    end

  end
end
