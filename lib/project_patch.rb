require_dependency 'project'

module ProjectPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # Gets the full rate for this project over the given interval.
    def gm_full_rate(interval)
      GmRate.where(kind: 'project_revenue_full', project_id: id).last
    end
  end
end
