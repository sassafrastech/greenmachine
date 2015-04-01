# Models an interval of time in days.
class GmInterval
  attr_accessor :start, :finish

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end
end
