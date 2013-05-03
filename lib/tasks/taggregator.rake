namespace :taggregator do

  desc "Check the status of the daily emails, email admins letting them know"
  task :check_daily_email_status => :environment do
    Star::DailyEmailStatus.new.perform
  end

  desc "Asynchronously start enqueueing metric updates for active campaign photos"
  task :queue_campaign_photos => :environment do
    Star::PhotoUpdater::Enqueuer.perform_async
  end

  desc "Clean up photos and users that are not relevant to campaigns"
  task :cleanup => :environment do
    # Remove any photos that aren't in campaigns
    Photo.includes(:campaign_photos).all.select{|p| p.campaign_photos.empty?}.each(&:destroy)
    # Remove any users that don't have photos
    User.includes(:photos).all.select{|u| u.photos.empty? and u.access_token.nil? and u.email.nil?}.each(&:destroy)
    # Remove any tags that don't have photos or campaigns
    Tag.includes(:photo_tags, :campaign_tags).all.select{|t| t.photo_tags.empty? and t.campaign_tags.empty?}.each(&:destroy)
  end


end
