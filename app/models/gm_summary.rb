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

  def +(other)
    sum = self.class.new
    by_user.keys.each do |u|
      sum[u] = self[u].nil? && other[u].nil? ? nil : (self[u] || 0) + (other[u] || 0)
    end
    sum
  end

  def -(other)
    diff = self.class.new(total_type: total_type)
    by_user.keys.each do |u|
      diff[u] = self[u].nil? && other[u].nil? ? nil : (self[u] || 0) - (other[u] || 0)
    end
    diff
  end

  def /(other)
    quotient = self.class.new(total_type: :average)
    by_user.keys.each do |u|
      _other = other.is_a?(Numeric) ? other : other[u]
      quotient[u] = if self[u].nil? && _other.nil?
        nil
      elsif (_other || 0) == 0
        0
      else
        (self[u] || 0) / _other
      end
    end
    quotient
  end

  def *(other)
    product = self.class.new
    by_user.keys.each do |u|
      _other = other.is_a?(Numeric) ? other : other[u]
      product[u] = self[u].nil? && _other.nil? ? nil : (self[u] || 0) * (_other || 0)
    end
    product
  end

  def [](user)
    by_user[user]
  end

  def []=(user, val)
    by_user[user] = val == 0 ? nil : val
  end
end
