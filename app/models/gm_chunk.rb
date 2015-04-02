# Holds a number of hours and a rate, and optionally an issue. Represents a chunk of work.
class GmChunk
  attr_accessor :hours, :rate, :issue

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def dollars
    @dollars ||= hours * rate.val
  end
end