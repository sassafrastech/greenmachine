class AddIssueIdToRates < ActiveRecord::Migration
  def change
    add_column :gm_rates, :issue_id, :integer
  end
end
