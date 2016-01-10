class GmRate < ActiveRecord::Base
  unloadable
  include GmIntervalSearchable

  DISPLAY_FIELDS = %w(kind user user_type project issue val effective_on)
  USER_TYPES = %w(member employee contractor accountant ignore)
  KINDS = %w(revenue wage user_pto_election payroll_tax_pct general_expenses health_insurance)

  belongs_to :user
  belongs_to :project
  belongs_to :issue

  attr_accessor :multiple_matches
  alias_method :multiple_matches?, :multiple_matches

  validates :kind, :val, :effective_on, presence: true

  # Returns a 4 digit binary code (as a string) representing which attributes are present
  # Bit 1: Issue
  # Bit 2: Project
  # Bit 3: User
  # Bit 4: User type
  def sort_code
    @sort_code ||= %w(issue_id project_id user_id user_type).map{ |a| self[a].present? ? 1 : 0 }.join
  end

  def cancellation?
    val.nil?
  end

end
