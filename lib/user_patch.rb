require_dependency 'user'

module UserPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # Gets the GmRate for this user with the given type and project, over the given interval.
    def gm_rate(type, project, interval)
      GmRate.new(val: type == :revenue ? 8 : 6)
    end

    def gm_type(interval)
      @gm_type ||= GmUserType.where(user_id: id).last
    end
  end
end
