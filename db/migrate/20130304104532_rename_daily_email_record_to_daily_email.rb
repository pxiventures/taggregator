class RenameDailyEmailRecordToDailyEmail < ActiveRecord::Migration
  def change
    rename_table :daily_email_records, :daily_emails
  end
end
