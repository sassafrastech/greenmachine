# Holds a number of hours and a rate, and optionally an issue. Represents a chunk of work.
class GmChunk
  attr_accessor :issue, :hours, :dollars, :rates

  def initialize(attribs = {})
    self.hours = 0
    self.dollars = 0
    self.rates = []

    # Initial entry.
    if attribs[:hours] || attribs[:rate]
      add_entry(hours: attribs.delete(:hours), rate: attribs.delete(:rate))
    end

    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  # Adds an entry (with hours and rate) to this chunk.
  # Keeps running dollar total.
  def add_entry(params)
    params[:rate] ||= GmRate.new(val: 0)
    self.hours += params[:hours]
    self.dollars += params[:hours] * params[:rate].val
    self.rates << params[:rate].val unless rates.include?(params[:rate].val)
  end

  def rate
    @rate ||= GmRate.new(val: dollars / hours)
  end

  def multiple_rates?
    rates.size > 1
  end

  def rounded_hours
    hours.round(2)
  end
end
