class AddIssueIdToRates < ActiveRecord::Migration[4.2]
  def change
    add_column :gm_rates, :issue_id, :integer
  end
end
