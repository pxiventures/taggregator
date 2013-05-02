# Public: The DailyEmail model acts as the interface for sending emails and
# also stores a record of when the daily email was sent.
#
# Creating a DailyEmail model will cause emails to send!
class DailyEmail < ActiveRecord::Base
  attr_accessible :emails_sent, :sent_at

  before_create :send_emails

  # Public: Check if a daily email must be sent. This is true if the last daily
  # email was more than 1 day(ish) ago.
  def self.must_send?
    last_daily_email = self.order("sent_at DESC").first
    (!last_daily_email || last_daily_email.sent_at <= 23.hours.ago)
  end

  # Public: Check if a daily email can be send. There must be 3 campaigns
  # running and all campaigns must have their winning photo recorded.
  #
  # Do not check when the last email was sent. That way we can use this to test
  # and see if the system is in a valid or invalid state and warn
  # administrators.
  def self.can_send?
    Campaign.not_sponsored.running.length == 3 and Campaign.not_sponsored.where("end_date < ? and winning_photo_id IS NULL", Time.now).count == 0
  end

  # Public: Combine must send and can send.
  #
  # 'you CAN send a daily email, but you SHOULD not because one was sent 1 hour
  # ago'.
  #
  # 'you MUST send a daily email, but you CANNOT because there are only
  # 2 campaigns'.
  def self.should_send?
    must_send? and can_send?
  end
  
  # Convenience method to queue a test email to admins only, 
  # without persisting any record of an email.
  def self.test_send_to_admins
    deliver_to User.emailable.where(admin: true), admin_test_warning: true
  end
  

  private
  
  def send_emails
    self.sent_at ||= Time.now
    result = self.class.deliver_to User.emailable
    self.emails_sent ||= result.length
  end

  def self.deliver_to(users, opts = {})
    users.map do |user|
      CampaignMailer.delay.daily_email user.id, opts
    end
  end


end
