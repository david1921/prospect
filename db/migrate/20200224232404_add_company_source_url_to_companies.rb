class AddCompanySourceUrlToCompanies < ActiveRecord::Migration[6.0]
  def change
     add_column :companies, :source_url, :string
  end
end
