class AddColumnsToCompaniesAndKeyPeople < ActiveRecord::Migration[6.0]
  def change
     add_column :companies, :is_our_customer, :boolean, default:false
     add_column :key_people, :last_time_contacted, :datetime
  end
end
