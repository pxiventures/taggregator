describe PhotoPresenter do

  describe "#position_in_campaigns" do
    it "should return a phrase related to a campaign a photo is in" do
      photo = FactoryGirl.create :photo
      campaign = FactoryGirl.create :campaign
      photo.add_to_campaign campaign
      presenter = PhotoPresenter.new(photo, view)
      presenter.position_in_campaigns.should include("1st in")
      presenter.position_in_campaigns.should include campaign.name
    end

    it "should mention all the campaigns a photo is in" do
      photo = FactoryGirl.create :photo
      campaigns = 2.times.map do
        FactoryGirl.create :campaign
      end
      campaigns.each{|c| photo.add_to_campaign c}

      presenter = PhotoPresenter.new(photo, view)
      campaigns.each do |c|
        presenter.position_in_campaigns.should include c.name
      end
      presenter.position_in_campaigns.should include "and 1st in"
    end

  end

end
