# Internal: Root admin controller. Shows links to a bunch of other things.
class Admin::RootController < AdminController
  load_and_authorize_resource :campaign, parent: false, only: [:index]

  # Public: Index page for admin panel. Shows links to other admin pages and
  # also gives a quick view of the current campaigns and their recent photos.
  def index
    @campaigns = @campaigns.includes(:photos, :approved_photos).order("end_date DESC").page(params[:page])
  end

  # Public: Shows a list of 'top tags' on Instagram based on the Twitter
  # sprinkle-hose.
  #
  # Aggregates the data out of Redis. Look at the top_statistics rake task for
  # more information about how the data is stored. But basically this fetches
  # all the 10-minute interval data it needs and then aggregates that together
  # in a hash, finally returning a sorted array.
  #
  # Takes a couple of parameters (with defaults)
  #
  # time - How many 10 minute intervals to look back over. Default is 6
  # (one hour). Try '1' for really up to date stats, or 60 for 10 hours worth.
  # count - Total number of tags to display.
  def top_tags

    keys = ((params[:time] && params[:time].to_i) || 6).times.map do |i| 
      at = (i*10).minutes.ago
      "#{at.year}:#{at.month}:#{at.day}:#{at.hour}:#{at.min/10}"
    end

    hashtags = keys.reduce({}) do |acc, k|
      $redis.zrevrange(k, 0, -1, {with_scores: true}).each do |hashtag, value|
        acc[hashtag] = (acc[hashtag] || 0) + value.to_i
      end
      acc
    end

    @tags = hashtags.to_a.sort{|a, b| b.second <=> a.second}.map{|h| {name: h[0], value: h[1]}}.first((params[:count] && params[:count].to_i) || 50)

    respond_to do |format|
      format.html
      format.json { render json: @tags }
    end

  end

  def daily_email
    record = DailyEmail.create!
    redirect_to admin_root_path, notice: "Sending #{record.emails_sent} daily email(s) asynchronously. Check Sidekiq to monitor status."
  end
  
  def daily_email_test
    DailyEmail.test_send_to_admins
    redirect_to admin_root_path, notice: "Sending daily email(s) asynchronously to admins only. Check Sidekiq to monitor status."
  end
  
  def force_update
    Star::PhotoUpdater::Enqueuer.perform_async(true)
    redirect_to admin_root_path, notice: "OK, forced a photo update for all photos in active campaigns. Check Sidekiq to monitor status."
  end

end
