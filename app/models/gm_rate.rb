# Represents a rate over a particular interval.
class GmRate
  # multiple_matches indicates that more than one rate was found in the given interval
  attr_accessor :val, :multiple_matches

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  alias_method :multiple_matches?, :multiple_matches
end
