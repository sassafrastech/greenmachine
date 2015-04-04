class RenameGmUserTypesAndAddCols < ActiveRecord::Migration
  def change
    rename_table :gm_user_types, :gm_user_info
    rename_column :gm_user_info, :name, :user_type
  end
end
