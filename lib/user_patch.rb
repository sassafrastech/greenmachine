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

    def gm_type(interval)
      @gm_type ||= GmUserType.where(user_id: id).last
    end
  end
end
