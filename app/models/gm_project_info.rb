class GmProjectInfo < ActiveRecord::Base
  belongs_to :project
  delegate :name, to: :project

  # Gets the full rate for this project over the given interval. May return nil.
  def gm_full_rate(interval)
    @gm_full_rate ||= {}
    return @gm_full_rate[interval] if @gm_full_rate[interval]
    @gm_full_rate[interval] = GmRateFinder.find(:revenue, interval, project: project)
  end

end
