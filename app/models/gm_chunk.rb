# Holds a number of hours and a rate, and optionally an issue. Represents a chunk of work.
class GmChunk
  UNBILLED_ACTIVITY_ID = 11
  UNBILLED_UNPAID_ACTIVITY_ID = 17

  attr_accessor :issue, :rates,
    :billed_hours, :unbilled_hours, :total_hours,
    :billed_dollars, :unbilled_dollars, :total_dollars

  def initialize(attribs = {})
    self.billed_hours = 0
    self.unbilled_hours = 0
    self.total_hours = 0
    self.billed_dollars = 0
    self.unbilled_dollars = 0
    self.total_dollars = 0
    self.rates = []

    # Initial entry.
    if attribs[:hours] || attribs[:rate]
      add_entry(hours: attribs.delete(:hours), rate: attribs.delete(:rate), activity_id: attribs.delete(:activity_id))
    end

    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  # Adds an entry (with hours and rate) to this chunk.
  # Keeps running dollar total.
  def add_entry(params)
    params[:rate] ||= GmRate.new(val: 0)
    if params[:activity_id] == UNBILLED_ACTIVITY_ID
      self.unbilled_hours += params[:hours]
      self.unbilled_dollars += params[:hours] * params[:rate].val
    else
      self.billed_hours += params[:hours]
      self.billed_dollars += params[:hours] * params[:rate].val
    end
    self.total_hours += params[:hours]
    self.total_dollars += params[:hours] * params[:rate].val
    self.rates << params[:rate].val unless rates.include?(params[:rate].val)
  end

  def rate(hide_unbilled = false)
    rate_hours = hide_unbilled ? billed_hours : total_hours
    rate_dollars = hide_unbilled ? billed_dollars : total_dollars
    @rate ||= GmRate.new(val: rate_hours.zero? ? 0 : (rate_dollars / rate_hours))
  end

  def multiple_rates?
    rates.size > 1
  end

  def rounded_billed_hours
    billed_hours.round(2)
  end

  def rounded_unbilled_hours
    unbilled_hours.round(2)
  end

  def rounded_total_hours
    total_hours.round(2)
  end
end
