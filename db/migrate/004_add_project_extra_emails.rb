class AddProjectExtraEmails < ActiveRecord::Migration
  def change
    add_column :projects, :gm_extra_emails, :text
  end
end
