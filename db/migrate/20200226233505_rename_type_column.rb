class RenameTypeColumn < ActiveRecord::Migration[6.0]
  def change
    rename_column :companies, :type, :company_type
  end
end
