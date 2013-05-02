# Public: Classes/workers that deal with updating photo information (likes
# and comments, for example).
class Star::PhotoUpdater

  class Enqueuer
    include Sidekiq::Worker
    sidekiq_options :unique => true

    def perform(force = false)
      # queue an update for every photo in a currently active campaign
      Campaign.running.each do |campaign|
        campaign.photos.each do |photo|
          photo.queue_for_updates(force)
        end
      end
    end

  end

  class Updater
    include Sidekiq::Worker
    sidekiq_options :unique => true

    def perform(photo_id, force=false)

      begin 
        photo = Photo.find(photo_id)
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.warn "Photo #{photo_id} has gone away"
      else
        # Check we still need to do this
        if force || photo.need_to_update_metrics?
          response = photo.update_metrics(true)

          if response
            rate_limit_remaining = response.headers["X-Ratelimit-Remaining"].to_i
            pause_for_rate_limit rate_limit_remaining
          end
        end
      end

    end

    def pause_for_rate_limit(rate_limit_remaining)
      if rate_limit_remaining == 0
        puts "WARNING: Ran out of API calls, sleeping for a while..."
        sleep 120
      else
        # TODO: While we're working on a Sidekiq implementation, this is
        # disabled.
        
        # So long as the async queue size is < 1/10th of our rate limit
        # remaining, just go straight ahead and process another photo.
        #if Resque.size(self.queue) > rate_limit_remaining / 10
        #  sleep_time = [86400 / rate_limit_remaining, 120].min
        #  puts "Sleeping for #{sleep_time}, rate limit remaining: #{rate_limit_remaining}"
        #  sleep sleep_time
        #end
      end
    end

  end
end
