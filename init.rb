# Secret tokens, etc.
require 'secrets'

# Patches to the Redmine core.
require 'user_patch'
require 'project_patch'
ActionDispatch::Callbacks.to_prepare do
  User.send(:include, UserPatch) unless User.included_modules.include? UserPatch
  Project.send(:include, ProjectPatch) unless Project.included_modules.include? ProjectPatch
end

gm = Redmine::Plugin.register :greenmachine do
  name 'Sassafras Green Machine'
  author 'Tom Smyth'
  description 'Sassafras Billing Plugin'
  version '0.0.1'
  url 'https://github.com/sassafrastech/greenmachine'
  author_url 'http://sassafras.coop/about'

  menu :top_menu, :polls, { controller: 'gm_reports', action: 'show' },
    caption: 'GreenMachine', if: -> (x) { GmUserInfo.can_view?(User.current) }
end

ActiveSupport::Dependencies.autoload_paths << "#{gm.directory}/app/models/concerns"

$qb_oauth_consumer = OAuth::Consumer.new(QB_KEY, QB_SECRET, {
  :site                 => "https://oauth.intuit.com",
  :request_token_path   => "/oauth/v1/get_request_token",
  :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
  :access_token_path    => "/oauth/v1/get_access_token"
})