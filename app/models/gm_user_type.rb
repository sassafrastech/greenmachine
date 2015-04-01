# Stores the user's type for GreenMachine purposes.
class GmUserType < ActiveRecord::Base
  unloadable
  belongs_to :user

  # We can't use Redmine's permission system for this since it's project-based only.
  # For now anybody that has a user type can see the system.
  def self.can_view?(user)
    user.present? && current_for(user).try(:active?)
  end

  def self.current_for(user)
    where(user_id: user.id).first
  end

  def active?
    name != 'inactive'
  end
end
