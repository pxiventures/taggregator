class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.references :user
      t.string :uid
      t.string :url

      t.timestamps
    end
  end
end
