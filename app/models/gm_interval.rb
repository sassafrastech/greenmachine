# Models an interval of time in days.
class GmInterval
  attr_accessor :start, :finish

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  # Return true if this interval extends from the beginning to the end
  # of a single month.
  def full_month?
    start.day == 1 &&
      (finish + 1).month != finish.month &&
      start.month == finish.month &&
      start.year == finish.year
  end
end
