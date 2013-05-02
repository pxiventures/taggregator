class RemoveAdmins < ActiveRecord::Migration
  def up
    drop_table :admins
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
