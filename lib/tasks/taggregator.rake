namespace :taggregator do

  desc "Check the status of the daily emails, email admins letting them know"
  task :check_daily_email_status => [:environment] do
    Star::DailyEmailStatus.new.perform
  end

  desc "Asynchronously start enqueueing metric updates for active campaign photos"
  task :queue_campaign_photos => [:environment] do
    Star::PhotoUpdater::Enqueuer.perform_async
  end

end
