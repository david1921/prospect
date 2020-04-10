class CreateKeyPeople < ActiveRecord::Migration[6.0]
  def change
    create_table :key_people do |t|
      t.string :email_address
      t.string :first_name
      t.string :last_name
      t.string :title
      t.integer :company_id
      t.boolean :email_verified, default: false
      t.string :phone_number
      t.integer :no_of_times_contacted,default: 0

      t.timestamps
    end
  end
end
