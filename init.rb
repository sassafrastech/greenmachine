# Patches to the Redmine core.
require 'user_patch'
require 'project_patch'
ActionDispatch::Callbacks.to_prepare do
  User.send(:include, UserPatch) unless User.included_modules.include? UserPatch
  Project.send(:include, ProjectPatch) unless Project.included_modules.include? ProjectPatch
end

Redmine::Plugin.register :green_machine do
  name 'Sassafras Green Machine'
  author 'Tom Smyth'
  description 'Sassafras Billing Plugin'
  version '0.0.1'
  url 'https://github.com/sassafrastech/greenmachine'
  author_url 'http://sassafras.coop/about'

  menu :top_menu, :polls, { controller: 'gm_reports', action: 'show' },
    caption: 'GreenMachine', if: -> (x) { GmUserType.can_view?(User.current) }
end
