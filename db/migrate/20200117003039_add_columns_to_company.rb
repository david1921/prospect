class AddColumnsToCompany < ActiveRecord::Migration[6.0]
  def change
       add_column :companies, :populated, :boolean, default: false
       add_index :companies, :domain, unique: true
  end
end
