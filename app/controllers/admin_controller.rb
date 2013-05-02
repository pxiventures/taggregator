# Base admin controller, all others should inherit from this to gain auth
# requirements.
class AdminController < ApplicationController
  before_filter :admin_or_sponsor!

  before_filter do
    @last_daily_email = DailyEmail.last
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to admin_root_url, :alert => exception.message
  end
end
