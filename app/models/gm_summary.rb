# Represents a summary row in the main grid.
class GmSummary
  attr_accessor :by_user, :total_type

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
    self.total_type ||= :sum
    self.by_user = {}
  end

  def total
    return @total if @total
    non_nil = by_user.values.reject(&:nil?)
    @total = non_nil.sum
    @total /= non_nil.size if total_type == :average && !non_nil.empty?
    @total
  end

  def -(other)
    diff = self.class.new(total_type: total_type)
    by_user.keys.each do |u|
      d = (by_user[u] || 0) - (other.by_user[u] || 0)
      diff.by_user[u] = d == 0 ? nil : d
    end
    diff
  end
end
