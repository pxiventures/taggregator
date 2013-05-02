class AddDefaultApprovedStateToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :default_approved_state, :boolean, allow_nil: false, default: true
  end
end
