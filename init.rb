# Secret tokens, etc.
require 'secrets'

# Patches to the Redmine core.
require 'user_patch'
require 'project_patch'
ActionDispatch::Callbacks.to_prepare do
  User.send(:include, UserPatch) unless User.included_modules.include? UserPatch
  Project.send(:include, ProjectPatch) unless Project.included_modules.include? ProjectPatch
end

Redmine::Plugin.register :greenmachine do
  name 'Sassafras Green Machine'
  author 'Tom Smyth'
  description 'Sassafras Billing Plugin'
  version '0.0.1'
  url 'https://github.com/sassafrastech/greenmachine'
  author_url 'http://sassafras.coop/about'

  menu :top_menu, :polls, { controller: 'gm_reports', action: 'show' },
    caption: 'GreenMachine', if: -> (x) { GmUserType.can_view?(User.current) }
end

$qb_oauth_consumer = OAuth::Consumer.new(QB_KEY, QB_SECRET, {
  :site                 => "https://oauth.intuit.com",
  :request_token_path   => "/oauth/v1/get_request_token",
  :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
  :access_token_path    => "/oauth/v1/get_access_token"
})