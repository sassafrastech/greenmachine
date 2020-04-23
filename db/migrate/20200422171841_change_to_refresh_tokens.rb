class ChangeToRefreshTokens < ActiveRecord::Migration[5.2]
  def change
    rename_column :gm_credentials, :token, :access_token
    rename_column :gm_credentials, :secret, :refresh_token
    add_column :gm_credentials, :token_expires_at, :datetime
  end
end
