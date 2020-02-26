class IncreaseTokenLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :gm_credentials, :token, :string, :limit => 1000
  end
end
