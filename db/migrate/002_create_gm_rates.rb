class CreateGmRates < ActiveRecord::Migration
  def change
    create_table :gm_rates do |t|
      t.string :kind, null: false
      t.integer :user_id
      t.integer :project_id
      t.date :effective_on, null: false
      t.decimal :val, null: false, precision: 15, scale: 2
    end
    add_index :gm_rates, :kind
    add_index :gm_rates, :user_id
    add_index :gm_rates, :project_id
    add_index :gm_rates, :effective_on
  end
end
