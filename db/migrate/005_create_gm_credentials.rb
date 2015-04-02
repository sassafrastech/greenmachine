class CreateGmCredentials < ActiveRecord::Migration
  def change
    create_table :gm_credentials do |t|
      t.string :token
      t.string :secret
      t.string :company_id
    end
  end
end
