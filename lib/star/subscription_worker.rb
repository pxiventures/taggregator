class Star::SubscriptionWorker
  include Sidekiq::Worker
  sidekiq_options :unique => true

  def perform(subscription_id)
    subscription = Subscription.find(subscription_id)
    puts "Fetching photos tagged #{subscription.tag} (Subscription: #{subscription_id})"

    request_params = {
      client_id: AppConfig.instagram.client_id,
      client_secret: AppConfig.instagram.client_secret,
      min_tag_id: subscription.min_tag_id
    }
    response = Star::Requester.get "tags/#{subscription.tag}/media/recent", request_params
    if response.success?
      data = response.body
      # Because the Instagram gem sucks
      unless data.is_a? Array
        data = data.data
      end
      puts "Got #{data.length} images..."
      data.each do |media| 
        Photo.create_or_update_from_instagram(media)
      end
      subscription.update_attribute(:min_tag_id, response.body.pagination.min_tag_id)
      puts "New min_tag_id is #{subscription.min_tag_id}"
    else
      puts "Response failed with error code: #{response.code}"
      puts "Body: #{response.body}"
    end

  end
end
