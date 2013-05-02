FactoryGirl.define do
  factory :campaign_photo do

    photo
    campaign

    approved true
    moderated false

  end
end
