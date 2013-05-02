class CampaignMailer < ActionMailer::Base
  default from: AppConfig.email.from
  helper ApplicationHelper

  def daily_email(user, opts={})
    
    # set a flag that this email should contain an admin warning message
    @admin_test_warning = opts[:admin_test_warning]
    
    @default_mail_params = {utm_source:"dailyemail", utm_medium:"email", utm_content:"#{AppConfig.app_name}", utm_campaign:"Daily Email", only_path: false}
    
    @user = user.is_a?(User) ? user : User.find(user)

    @recent_campaigns = Campaign.not_sponsored.ended_with_winner.limit(3)
    @running_campaigns = Campaign.not_sponsored.running.limit(3)
    @users_results = Photo.joins(:campaign_photos).where(photos: {user_id: @user.id}, campaign_photos: {campaign_id: @recent_campaigns}).uniq

    mail to: @user.email, subject: "[#{AppConfig.app_name}] Your Daily #{AppConfig.app_name} news"
  end
end
