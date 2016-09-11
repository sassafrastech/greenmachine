class CreateGmProjectInfos < ActiveRecord::Migration
  def change
    create_table :gm_project_infos do |t|
      t.references :project, index: true, foreign_key: true
      t.integer :gm_qb_customer_id
      t.text :gm_extra_emails

      t.timestamps null: false
    end

    Project.all.each do |p|
      if p.gm_qb_customer_id || p.gm_extra_emails
        GmProjectInfo.create(
          project: p,
          gm_qb_customer_id: p.gm_qb_customer_id,
          gm_extra_emails: p.gm_extra_emails,
        )
      end
    end
  end
end
