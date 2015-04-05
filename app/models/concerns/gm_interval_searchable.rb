module GmIntervalSearchable
  extend ActiveSupport::Concern

  included do
    # Returns all rates effective before the last date of the interval.
    scope :applicable_to, -> (interval) { where('effective_on <= ?', interval.finish).order('effective_on') }
  end
end