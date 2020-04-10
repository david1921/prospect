class AddContactedToJoinProspectsTable < ActiveRecord::Migration[6.0]
  def change
      add_column :customer_prospects, :has_been_contacted, :boolean, default:false
      add_column :customer_prospects, :last_time_contacted, :datetime
  end
end
