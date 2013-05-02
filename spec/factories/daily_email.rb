FactoryGirl.define do
  factory :daily_email do
    sent_at Time.now
    emails_sent 1
  end
end
