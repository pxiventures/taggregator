class AdminMailer < ActionMailer::Base
  default from: AppConfig.email.from
  default to: AppConfig.email.to

  def daily_email_status(can_send)
    @can_send = can_send
    @ended_campaigns_need_reporting = Campaign.where("end_date < ? and winning_photo_id IS NULL", Time.now) unless @can_send
    subject = "[#{AppConfig.app_name}] " + (can_send ? "Daily email can be sent now!" : "Problem with daily email, please fix!")
    mail subject: subject
  end

  # Public: Send an Instagram rate limit warning to the admins. Use Memcache
  # to ensure we don't send too many emails (limit to one an hour).
  #
  # In development the cache won't prevent this happening. Combined with
  # letter_opener you might suddenly get a lot of tabs opening...
  #
  # Returns nil or a mail object (for you to deliver)
  def instagram_rate_limit_warning(rate_limit_remaining, url)
    # Key-based expiration
    @rate_limit_remaining = rate_limit_remaining
    @url = url
    cache_key = ["instagram_rate_limit_warning", Time.now.hour]
    return nil if Rails.cache.fetch cache_key
    Rails.cache.write cache_key, true
    mail subject: "[#{AppConfig.app_name}] WARNING: Instagram rate limit low"
  end
end
