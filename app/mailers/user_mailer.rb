# Public: Mailer for emailing specific users e.g. about their email activation.
class UserMailer < ActionMailer::Base
  default from: AppConfig.email.from

  def verify_email(user)
    @user = user
    mail to: @user.email, subject: "[#{AppConfig.app_name}] Please verify your email address"
  end
end
