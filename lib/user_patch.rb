require_dependency 'user'

module UserPatch
  PTO_DAYS_PER_MONTH = 3

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # Gets the GmRate for this user for the given project, over the given interval.
    def gm_project_rate(project, interval)
      adjusted = GmRateFinder.find(:revenue, interval, user: self, project: project)
      adjusted || project.gm_full_rate(interval) # User's rate is the full rate if no adjusted rate.
    end

    def gm_project_wage_rate(project, interval)
      GmRateFinder.find(:wage, interval, project: project) || gm_wage_rate(interval)
    end

    # Gets the issue rate, if one exists. Returns nil if not.
    def gm_issue_rate(issue, interval)
      GmRateFinder.find(:revenue, interval, user: self, issue: issue)
    end

    def gm_wage_rate(interval)
      # If there is a user_wage_base rate for this user and val is not nil, use it.
      user_rate = GmRateFinder.find(:wage, interval, user: self)
    end

    def gm_info(interval)
      @gm_info ||= {}
      @gm_info[interval] ||= GmUserInfo.where(user_id: id).applicable_to(interval).last
    end

    def gm_user_type(interval)
      gm_info(interval).try(:user_type)
    end

    def gm_pto_election(interval)
      if gm_info(interval).internal?
        GmRateFinder.find(:user_pto_election, interval, user: self)
      else
        nil
      end
    end

    def gm_gross_pto(interval)
      gm_info(interval).has_pto? ? gm_pto_election(interval).val * gm_wage_rate(interval).val * PTO_DAYS_PER_MONTH : nil
    end

    def gm_health_insurance(interval)
      GmRateFinder.find(:health_insurance, interval, user: self)
    end
  end
end
