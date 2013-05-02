class AddUserCanReceiveMailFlag < ActiveRecord::Migration
  def up
    add_column :users, :can_receive_mail, :boolean, default: true
    User.update_all(can_receive_mail: true)
  end

  def down
    remove_column :users, :can_receive_mail
  end
end
