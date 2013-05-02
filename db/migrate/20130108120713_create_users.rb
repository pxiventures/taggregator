class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :access_token
      t.string :username
      t.string :full_name
      t.string :uid
      t.string :profile_picture

      t.timestamps
    end
  end
end
