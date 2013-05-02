class CampaignsController < ApplicationController
  before_filter :load_started_campaign, except: [:index, :top_photos]
  
  # Public: Currently this is the 'home' page when you are not logged in.
  def index
    # Preserve some parameters if the user is logged in.
    redirect_to params.except(:home_page).merge(action: "index", controller: "photos") and return if current_user
    # Not all of these instance variables are used by all iterations of the
    # front page, but at least this way you can pick and choose when designing
    # them.

    @campaigns = Campaign.running.limit(3)
    @finished_campaigns = Campaign.ended_with_winner.order("end_date DESC").limit(3)
    @recent_activity = Rails.cache.fetch("recent_activity", expires_in: 10.minutes) do
      Photo.joins(:campaigns).where(:campaigns => {id: @campaigns}).order("created_at DESC").limit(6)
    end

    respond_to do |format|
      format.html do
        render "campaigns/split_tests/original_design"
      end
      format.json { render json: @campaigns }
    end
  end

  # Returns the 3 running campaigns and their top photos for use in an embedded
  # web view in a mobile app.
  def top_photos
    @campaigns = Campaign.not_sponsored.running.limit(3)
    json = @campaigns.map{|c| CampaignSerializer.new(c, root: false).as_json}
    json.each do |campaign|
      campaign["top_photo"] = PhotoSerializer.new(Campaign.find(campaign[:id]).top_photo, root: false).as_json
    end
    render json: json
  end

  # Show a single campaign & leaderboard
  def show
    @users_photos = @campaign.photos.where(user_id: current_user.id) if current_user
  end

  def embed
    @photos = @campaign.ranked_approved_photos.page(params[:page])
    respond_to do |format|
      format.js
      format.html do
        render layout: "embed"
      end
    end
  end

  # Public: JS endpoint for returning the top 10 photos for a given campaign
  #
  # /campaigns/1/leaderboard
  # # => JSON array of photos.
  def leaderboard
    render json: (@campaign.ranked_approved_photos.first(10) || []), campaign_to_score: @campaign
  end

end
