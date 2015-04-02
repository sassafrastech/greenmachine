class AddProjectCustomerField < ActiveRecord::Migration
  def change
    add_column :projects, :gm_qb_customer_id, :integer
  end
end
