class GmProjectInfo < ActiveRecord::Base
  belongs_to :project
  delegate :name, to: :project

  # Gets the full rate for this project over the given interval.
  def gm_full_rate(interval)
    if name == 'Internal'
      GmRate.new(val: 0)
    else
      GmRateFinder.find(:revenue, interval, project: project)
    end
  end

end
