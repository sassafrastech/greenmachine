class CreateGmProjectInfos < ActiveRecord::Migration
  def change
    create_table :gm_project_infos do |t|
      t.references :project, index: true, foreign_key: true
      t.integer :gm_qb_customer_id
      t.text :gm_extra_emails

      t.timestamps null: false
    end
  end
end
