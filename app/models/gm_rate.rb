class GmRate < ActiveRecord::Base
  unloadable
  include GmIntervalSearchable

  attr_accessor :multiple_matches
  alias_method :multiple_matches?, :multiple_matches

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
