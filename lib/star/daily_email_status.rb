class Star::DailyEmailStatus
  include Sidekiq::Worker

  # Tell admins about whether a daily email needs to/can be sent.
  def perform
    return true if Rails.env =~ /development/i
    AdminMailer.daily_email_status(DailyEmail.can_send?).deliver if DailyEmail.must_send?
  end
end
