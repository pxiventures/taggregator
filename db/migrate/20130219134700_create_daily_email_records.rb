class CreateDailyEmailRecords < ActiveRecord::Migration
  def change
    create_table :daily_email_records do |t|
      t.datetime :sent_at
      t.integer :emails_sent

      t.timestamps
    end
  end
end
