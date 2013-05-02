class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user, :is_admin?, :access_denied, :json_for
  helper :layout

  before_filter :setup_gon

  def present(object, klass = nil)
    klass ||= "#{object.class}Presenter".constantize
    klass.new(object, view_context)
  end

  def default_serializer_options
    {root: false}
  end

  private 

  # Manually use serializer
  def json_for(target, options = {})
    options = default_serializer_options.merge(options)
    options[:scope] ||= self
    options[:url_options] ||= url_options
    target.active_model_serializer.new(target, options).to_json
  end

  # Internal: Set up gon variables. Gon allows you to configure stuff
  # server-side and have those variables available in the client-side JS.
  def setup_gon
    gon.logged_in = !current_user.nil?
    if current_user
      gon.access_token = current_user.access_token
    end
  end

  # Public: Filter for checking to make sure the user is logged in and
  # activated.
  def authorized!
    unless current_user and current_user.email.present?
      redirect_to root_path, alert: "You need to be logged in to view that!" and return if !current_user
      redirect_to email_path, alert: "To finish signing up, please supply your email address." and return if current_user.email.blank?
    else
      # WARNING: It is a little DB heavy to do this, but OK for low traffic.
      current_user.update_attributes(last_signed_in_at: Time.now) if !current_user.last_signed_in_at || current_user.last_signed_in_at < 1.hour.ago
    end
  end

  # Public: Filter for making sure the user is logged in + is an admin.
  def admin!
    redirect_to root_path, alert: "Not authorized" and return unless is_admin?
  end

  def admin_or_sponsor!
    redirect_to root_path, alert: "Not authorized!" and return unless is_admin? or is_sponsor?
  end
      

  # Public: Returns the current user or nil.
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id] rescue nil
  end

  # Public: True if the current user is an admin 
  def is_admin?
    current_user && current_user.admin?
  end

  def is_sponsor?
    current_user && current_user.sponsor.present?
  end

  # Public: Use to deny a user access to a page.
  def access_denied
    redirect_to main_app.root_url, alert: "Not authorized"
  end

  # Public: Use as a filter to load a campaign and ensure it is started.
  def load_started_campaign
    @campaign = Campaign.find(params[:campaign_id] || params[:id])
    raise ActionController::RoutingError.new('Not Found') unless @campaign.started?
  end

end
