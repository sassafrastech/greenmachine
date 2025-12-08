class AddProjectCustomerField < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :gm_qb_customer_id, :integer
  end
end
