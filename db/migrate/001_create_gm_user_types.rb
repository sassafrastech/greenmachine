class CreateGmUserTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :gm_user_types do |t|
      t.integer :user_id, null: false
      t.date :effective_on, null: false
      t.string :name, null: false
    end
    add_index :gm_user_types, :user_id
    add_index :gm_user_types, :effective_on
  end
end
