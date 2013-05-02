FactoryGirl.define do
  factory :sponsor do
    name "Mr. Sponsor"
    url "http://mrsponsor.com"
    before(:create) do |sponsor, evaluator|
      sponsor.user = FactoryGirl.create :user unless sponsor.user
    end
  end
end

