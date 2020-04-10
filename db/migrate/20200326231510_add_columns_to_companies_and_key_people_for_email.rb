class AddColumnsToCompaniesAndKeyPeopleForEmail < ActiveRecord::Migration[6.0]
  def change
       add_column :companies, :email_pattern1, :string
       add_column :companies, :email_pattern2, :string
       add_column :key_people, :email_bounced, :boolean, default:true
  end
end
