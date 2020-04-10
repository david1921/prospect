class CreateCustomerProspects < ActiveRecord::Migration[6.0]
  def change
    create_table :customer_prospects do |t|
      t.integer :customer_id
      t.integer :prospect_id

      t.timestamps
    end
  end
end
