class CreateGmCredentials < ActiveRecord::Migration[4.2]
  def change
    create_table :gm_credentials do |t|
      t.string :token
      t.string :secret
      t.string :company_id
    end
  end
end
