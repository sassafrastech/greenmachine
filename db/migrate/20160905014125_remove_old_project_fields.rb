class RemoveOldProjectFields < ActiveRecord::Migration[4.2]
  def change
    remove_column :projects, :gm_qb_customer_id, :integer
    remove_column :projects, :gm_extra_emails, :text
  end
end
