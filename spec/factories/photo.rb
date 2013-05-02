FactoryGirl.define do
  factory :photo do

    sequence(:uid){|n| "#{n}" }
    image_url {"http://instagram.com/images/#{uid}"}
    thumbnail_url {"http://instagram.com/thumbnails/#{uid}"}
    url {"http://instagr.am/#{uid}"}
    caption "This is a photo"
    user
    comments 0
    likes 0
    metrics_last_updated_at Time.now

  end
end
