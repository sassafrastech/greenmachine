# Stores the user's type for GreenMachine purposes.
class GmUserInfo < ActiveRecord::Base
  unloadable
  include GmIntervalSearchable

  belongs_to :user

  self.table_name = 'gm_user_info'

  # We can't use Redmine's permission system for this since it's project-based only.
  # For now anybody that has a user type can see the system.
  def self.can_view?(user)
    user.present? && current_for(user).try(:active?)
  end

  def self.current_for(user)
    where(user_id: user.id).applicable_to(GmInterval.new(start: Date.today, finish: Date.today)).last
  end

  def active?
    user_type != 'inactive'
  end

  def internal?
    %w(member employee).include?(user_type)
  end

  def ignore?
    user_type == 'ignore'
  end

  def payroll_tax?
    user_type == 'employee'
  end

  def has_pto?
    internal?
  end
end
