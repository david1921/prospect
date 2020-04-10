class AddMorecolumnsToCompanies < ActiveRecord::Migration[6.0]
  def change
        add_column :companies, :founder_blurb, :text
        add_column :companies, :key_people_blurb, :text
        add_column :companies, :has_valid_info, :boolean, default:false
        add_column :companies, :funding_stage, :string
        add_column :companies, :phone, :string
        add_column :companies, :source, :string
        add_column :companies, :linkedin_link, :string
        add_column :companies, :funding_amount, :string
        add_column :companies, :acquired_by, :string
  end
end
