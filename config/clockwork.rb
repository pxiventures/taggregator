require 'clockwork'

require 'sidekiq'
require_relative 'environment'

module Clockwork
  # This is also rake taggregator:queue_campaign_photos
  every 1.minute, 'queue_campaign_photos' do
    Star::PhotoUpdater::Enqueuer.perform_async
  end

  # This is also rake taggregator:check_daily_email_status
  every 1.hour, 'check_daily_email_status', at: '**:00' do
    Star::DailyEmailStatus.perform_async
  end
end
