class PhotosController < ApplicationController
  before_filter :authorized!
  
  # Public: Logged in home page.
  #
  # If the format is JSON, return the current user's Instagram photos instead.
  def index
    if session[:mobile]
      session[:mobile] = nil
      render text: "Done! Close this window (or wait...)" and return
    end

    respond_to do |format|
      format.html do
        if session[:first_sign_in]
          @first_sign_in = true
          session[:first_sign_in] = nil
        end
        @campaigns = Campaign.not_sponsored.running.limit(3)
        @ended_campaigns = Campaign.not_sponsored.ended_with_winner.limit(5)
        render :index
      end
      format.json { render json: current_user.recent_images(15) }
    end
  end

  # Public: Participating in is a snippet of HTML that shows the photos the
  # current user has in the current campaigns. By rendering this as a snippet,
  # the page responds a bit faster. This might not be the case any more given
  # the fact that we don't do any Instagram fetches on requests.
  def participating_in
    @campaigns = Campaign.running.limit(3)
    @participating_in = @campaigns.select{|c| c.participating_users.include? current_user}
    render partial: "participating_in", layout: false
  end

  # Internal: For JS purposes - fetch details about a photo.
  def show
    @photo = current_user.photos.find params[:id]
    respond_to do |format|
      format.html { redirect_to photos_path, alert: "Sorry, can't view individual photos yet" }
      format.json { render json: @photo }
    end
  end

  # Public: Add a photo to a campaign.
  def add_to_campaign
    photo = current_user.photos.find params[:id]
    campaign = Campaign.find params[:campaign_id]

    @photo_tags = photo.add_to_campaign campaign

    respond_to do |format|
      format.json do
        if @photo_tags
          render json: @photo_tags
        else
          render :status => 422, text: photo.errors.full_messages.to_sentence
        end
      end
    end
    
  end
  
  # Facebook callback after feed post.
  def fb_feed_post_callback
    redirect_to root_url
  end

end
