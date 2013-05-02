class AddEmailVerificationTokenAndVerifiedToUsers < ActiveRecord::Migration
  def up
    add_column :users, :email, :string
    add_column :users, :verification_token, :string
    add_column :users, :verified, :boolean, default: false
  end

  def down
    remove_column :users, :email
    remove_column :users, :verification_token
    remove_column :users, :verified
  end
end
