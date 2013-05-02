# Private: Handle webhook requests from Instagram that are in response to
# subscriptions we have placed. Instagram loosely follows the PubSubHubbub
# protocol, just without the very sensible fat pings (which means we have
# to eat up API to fetch images).
class RealtimeController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  # Private: Respond to an Instagram challenge.
	def instagram_challenge
    @verify_token = params["hub.verify_token"]
    if @verify_token == AppConfig.instagram.verify_token
      @challenge = params["hub.challenge"]
      render :text => @challenge, :layout => false
    else
      Rails.logger.warn "Received an invalid verify_token: #{@verify_token}"
      render :status => 500, :text => "Invalid verify_token", :layout => false
    end
	end

  # Private: Receive a notification from Instagram.
  def instagram_callback
    logger.info request.body
    Instagram.process_subscription(request.body) do |handler|
      handler.on_tag_changed do |id, change|
        process_change id, change
      end
    end
    render :nothing => true
  end

  private
  # Private: Process a realtime callback from Instagram; fetch recent media
  # and add to the database.
  #
  # id - the object_id of the change
  # change - the 'change' object (contains subscription_id, object, etc.)
  #
  # Example
  #
  #   process_change("bike", {"subscription_id" => 1, "object" => "tag", "object_id" => "bike", "time" => 123456789, "changed_aspect" => "media"}
  #
  # Returns nothing special.
  def process_change(id, change)
    logger.info "#process_change called for id: #{id}, change: #{change}"
    subscription = Subscription.find_by_original_id change["subscription_id"]
    unless subscription
      logger.info "No subscription found, creating one."
      subscription = Subscription.create!(original_id: change["subscription_id"],
                                         tag: id)
    end
    subscription.queue_fetch
  end

end
