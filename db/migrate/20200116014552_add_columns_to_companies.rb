class AddColumnsToCompanies < ActiveRecord::Migration[6.0]
  def change
    add_column :companies, :industry_tags, :text
    add_column :companies, :more_company_description, :text
    add_column :companies, :serves_traditional_market, :boolean
    add_column :companies, :revenue, :float
    add_column :companies, :no_of_employees, :integer,default: 0
    add_column :companies, :headquarters, :string
  end
end
