# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130423120444) do

  create_table "campaign_photos", :force => true do |t|
    t.integer  "photo_id"
    t.integer  "campaign_id"
    t.decimal  "score",       :precision => 10, :scale => 2
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.boolean  "moderated",                                  :default => false
    t.boolean  "approved"
  end

  add_index "campaign_photos", ["campaign_id"], :name => "index_campaign_photos_on_campaign_id"
  add_index "campaign_photos", ["photo_id", "campaign_id"], :name => "index_campaign_photos_on_photo_id_and_campaign_id", :unique => true
  add_index "campaign_photos", ["photo_id"], :name => "index_campaign_photos_on_photo_id"

  create_table "campaign_tags", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "tag_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "campaign_tags", ["campaign_id"], :name => "index_campaign_tags_on_campaign_id"
  add_index "campaign_tags", ["tag_id"], :name => "index_campaign_tags_on_tag_id"

  create_table "campaigns", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "winning_photo_id"
    t.boolean  "sent_new_push_notification", :default => false
    t.boolean  "default_approved_state",     :default => true
    t.integer  "sponsor_id"
  end

  create_table "daily_emails", :force => true do |t|
    t.datetime "sent_at"
    t.integer  "emails_sent"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "photo_tags", :force => true do |t|
    t.integer  "photo_id"
    t.integer  "tag_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "sticky",     :default => false
  end

  add_index "photo_tags", ["photo_id"], :name => "index_photo_tags_on_photo_id"
  add_index "photo_tags", ["tag_id", "photo_id"], :name => "index_photo_tags_on_tag_id_and_photo_id", :unique => true
  add_index "photo_tags", ["tag_id"], :name => "index_photo_tags_on_tag_id"

  create_table "photos", :force => true do |t|
    t.integer  "user_id"
    t.string   "uid"
    t.string   "url"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "image_url"
    t.string   "thumbnail_url"
    t.integer  "comments",                :default => 0
    t.integer  "likes",                   :default => 0
    t.datetime "metrics_last_updated_at"
    t.text     "caption"
  end

  add_index "photos", ["uid"], :name => "index_photos_on_uid", :unique => true
  add_index "photos", ["user_id"], :name => "index_photos_on_user_id"

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "sponsors", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.string   "url"
    t.string   "logo"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "subscriptions", :force => true do |t|
    t.integer  "original_id"
    t.string   "min_tag_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "queued",      :default => 0, :null => false
    t.string   "tag"
  end

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "access_token"
    t.string   "username"
    t.string   "full_name"
    t.string   "uid"
    t.string   "profile_picture"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.boolean  "admin",                   :default => false
    t.string   "email"
    t.string   "verification_token"
    t.boolean  "verified",                :default => false
    t.integer  "media"
    t.integer  "follows"
    t.integer  "followed_by"
    t.datetime "metrics_last_updated_at"
    t.datetime "last_signed_in_at"
    t.boolean  "can_receive_mail",        :default => true
  end

  add_index "users", ["uid"], :name => "index_users_on_uid", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username"

end
