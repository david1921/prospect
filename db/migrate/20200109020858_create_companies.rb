class CreateCompanies < ActiveRecord::Migration[6.0]
  def change
    create_table :companies do |t|
      t.string :domain
      t.string :name
      t.text :description
      t.text :description2
      t.text :description3

      t.timestamps
    end
  end
end
