# Internal: The subscriptions controller is for managing Instagram
# subscriptions e.g. viewing what we are subscribed to and creating and
# deleting realtime subscriptions.
class Admin::SubscriptionsController < AdminController
  # Public: List all Instagram subscriptions.
	def index
		@data = Instagram.subscriptions
	end

  # Public: Delete an Instagram subscription; deletes the locally cached
  # subscription too.
  def destroy  
    Instagram.delete_subscription({:id => params[:id]})
    local_subscription = Subscription.find_by_original_id params[:id]
    local_subscription.destroy if local_subscription
    redirect_to :admin_subscriptions
  end

  # Public: Create an Instagram subscription. Performs the task in a new thread
  # because Instagram checks the endpoint straight away, and if we're
  # single-threaded we will block.
  def create
    redirect_to :admin_subscriptions, alert: "Supply a tag name" and return if params[:tag_name].blank?

    Thread.new do |t|

      callback_url = instagram_callback_url

      request_params = {
        callback_url: callback_url,
        verify_token: APP_CONFIG.instagram.verify_token,
        object: "tag",
        aspect: "media",
        object_id: params[:tag_name],
        client_id: AppConfig.instagram.client_id,
        client_secret: AppConfig.instagram.client_secret
      }

      Star::Requester.post "subscriptions", request_params.to_param
    end

    sleep 1
    redirect_to :admin_subscriptions, :notice => "OK, sending subscription request"
  end

end
