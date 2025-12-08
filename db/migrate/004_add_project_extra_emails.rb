class AddProjectExtraEmails < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :gm_extra_emails, :text
  end
end
