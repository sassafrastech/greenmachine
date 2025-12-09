require_dependency 'project'

module ProjectPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def gm_project
      @gm_project ||= GmProjectInfo.find_or_create_by(project: self)
    end
    delegate :gm_qb_customer_id, :gm_extra_emails, :gm_full_rate, to: :gm_project
  end
end

unless Project.included_modules.include?(ProjectPatch)
  Project.send(:include, ProjectPatch)
end
