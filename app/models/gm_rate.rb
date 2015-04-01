class GmRate < ActiveRecord::Base
  unloadable

  attr_accessor :multiple_matches
  alias_method :multiple_matches?, :multiple_matches


end
