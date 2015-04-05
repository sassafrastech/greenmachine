require_dependency 'project'

module ProjectPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # Gets the full rate for this project over the given interval.
    def gm_full_rate(interval)
      if name == 'Sassafras Internal'
        GmRate.new(val: 0)
      else
        GmRate.where(kind: 'project_revenue_full', project_id: id).applicable_to(interval).last
      end
    end
  end
end
