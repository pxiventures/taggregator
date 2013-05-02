FactoryGirl.define do
  factory :user do

    trait :authenticated do
      access_token "access-token"
      verified true
      verification_token "example-token"
      email {"#{username}@taggregator.com"}
    end

    trait :admin do
      admin true
    end

    trait :is_a_sponsor do
      after(:create) do |user, evaluator|
        user.sponsor = FactoryGirl.create :sponsor, user: user unless user.sponsor
      end
    end
    
    full_name "John Doe"
    sequence(:uid){|n| "#{n}" }
    profile_picture "http://example.com/profile.jpg"
    username {"user-#{uid}"}

    media 0
    follows 0
    followed_by 0

    factory :authenticated_user, traits: [:authenticated]
    factory :sponsor_user, traits: [:is_a_sponsor, :authenticated]
    factory :admin_user, traits: [:authenticated, :admin]
  end
end
