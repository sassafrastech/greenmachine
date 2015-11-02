require_dependency 'user'

module UserPatch
  PTO_DAYS_PER_MONTH = 3

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # Gets the GmRate for this user for the given project, over the given interval.
    def gm_project_rate(project, interval)
      adjusted = GmRate.applicable_to(interval).where(kind: 'project_revenue_adjusted', user_id: id, project_id: project.id).last
      adjusted || project.gm_full_rate(interval) # User's rate is the full rate if no adjusted rate.
    end

    def gm_project_wage_rate(project, interval)
      GmRate.applicable_to(interval).where(kind: 'project_wage_base', project_id: project.id).last ||
        gm_wage_rate(interval)
    end

    # Gets the issue rate, if one exists. Returns nil if not.
    def gm_issue_rate(issue, interval)
      GmRate.applicable_to(interval).where(kind: 'issue_revenue_adjusted', user_id: id, issue_id: issue.id).last
    end

    def gm_wage_rate(interval)
      # If there is a user_wage_base rate for this user and val is not nil, use it.
      user_rate = GmRate.applicable_to(interval).where(kind: 'user_wage_base', user_id: id).last
      if user_rate && !user_rate.val.nil?
        user_rate
      elsif gm_info(interval) && gm_info(interval).user_type == 'member'
        GmRate.applicable_to(interval).where(kind: 'member_wage_base').last
      else
        nil
      end
    end

    def gm_info(interval)
      GmUserInfo.where(user_id: id).applicable_to(interval).last
    end

    def gm_pto_election(interval)
      if gm_info(interval).internal?
        GmRate.applicable_to(interval).where(kind: 'user_pto_election', user_id: id).last
      else
        nil
      end
    end

    def gm_gross_pto(interval)
      gm_info(interval).has_pto? ? gm_pto_election(interval).val * gm_wage_rate(interval).val * PTO_DAYS_PER_MONTH : nil
    end

    def gm_health_insurance(interval)
      GmRate.applicable_to(interval).where(kind: 'health_insurance', user_id: id).last
    end
  end
end
