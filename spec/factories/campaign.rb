FactoryGirl.define do
  factory :campaign do
    sequence(:name){|n| "A Campaign #{n}"}
    start_date { Time.now - 1.day }
    end_date { Time.now + 1.day }

    trait :sponsored do
      association :sponsor
    end

    after(:create) do |campaign, evaluator|
      FactoryGirl.create_list(:campaign_tag, 3, campaign: campaign)
    end

    factory :sponsored_campaign, traits: [:sponsored]
  end
end

