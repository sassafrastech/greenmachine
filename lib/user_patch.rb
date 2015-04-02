require_dependency 'user'

module UserPatch
  PTO_DAYS_PER_MONTH = 3

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # Gets the GmRate for this user for the given project, over the given interval.
    def gm_project_rate(project, interval)
      adjusted = GmRate.where(kind: 'project_revenue_adjusted', user_id: id, project_id: project.id).last
      adjusted || project.gm_full_rate(interval) # User's rate is the full rate if no adjusted rate.
    end

    def gm_wage_rate(interval)
      if gm_type(interval) && gm_type(interval).name == 'member'
        GmRate.where(kind: 'member_wage_base').last
      else
        GmRate.where(kind: 'user_wage_base', user_id: id).last
      end
    end

    def gm_type(interval)
      GmUserType.where(user_id: id).last
    end

    def gm_pto_election(interval)
      if %w(member employee).include?(gm_type(interval).name)
        GmRate.where(kind: 'user_pto_election', user_id: id).last
      else
        nil
      end
    end

    def gm_gross_pto(interval)
      gm_type(interval).has_pto? ? gm_pto_election(interval).val * gm_wage_rate(interval).val * PTO_DAYS_PER_MONTH : nil
    end
  end
end
