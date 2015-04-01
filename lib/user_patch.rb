require_dependency 'user'

module UserPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # Gets the GmRate for this user with the given type and project, over the given interval.
    def gm_rate(kind, project, interval)
      GmRate.where(kind: kind, user_id: id, project_id: project.id).last
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
  end
end
