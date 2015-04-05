class GmRate < ActiveRecord::Base
  unloadable
  include GmIntervalSearchable

  attr_accessor :multiple_matches
  alias_method :multiple_matches?, :multiple_matches


end
