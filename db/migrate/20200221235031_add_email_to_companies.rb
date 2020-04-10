class AddEmailToCompanies < ActiveRecord::Migration[6.0]
  def change
      add_column :companies, :is_consumer_centric, :boolean, default:false
      add_column :companies, :email, :string
  end
end
