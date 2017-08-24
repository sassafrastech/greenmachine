# Represents a summary row in the main grid.
class GmSummary
  attr_accessor :by_user, :total, :total_type, :show_zero, :interval, :internal_only
  alias_method :show_zero?, :show_zero
  alias_method :internal_only?, :internal_only

  def initialize(attribs = {})
    update(attribs)
    self.total_type ||= :sum
    self.by_user = {}
    self.show_zero = false
  end

  def update(attribs)
    attribs.each { |k,v| instance_variable_set("@#{k}", v) }
    @total = nil if total_type == :none
    if @internal_only && by_user
      by_user.select! { |user, _| user.gm_info(@interval).internal? }
    end
  end

  # `total_type` can be `:none`, `:sum`, `:average`, or a custom value. If a custom value, total
  # should be set manually.
  def total
    return nil if total_type == :none
    return @total if defined?(@total)
    update(internal_only: true) if @internal_only
    if total_type.in? [:sum, :average]
      non_nil = by_user.values.reject(&:nil?)
      @total = non_nil.sum
      @total /= non_nil.size if total_type == :average && !non_nil.empty?
    end
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
    quotient = self.class.new(total_type: :divide_totals)
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
    other_total = other.is_a?(Numeric) ? other : other.total
    quotient.total = total / other_total if total && other_total > 0
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
    by_user[user] == 0 && !show_zero? ? nil : by_user[user]
  end

  def []=(user, val)
    by_user[user] = val
  end
end
