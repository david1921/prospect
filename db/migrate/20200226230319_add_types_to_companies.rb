class AddTypesToCompanies < ActiveRecord::Migration[6.0]
  def change
    add_column :companies, :type, :string
    add_column :companies, :ipo_status, :string
  end
end
