# Secret tokens, etc.
require 'secrets'

# Patches to the Redmine core.
require 'user_patch'
require 'project_patch'

require_relative 'config/initializers/quickbooks'

ActiveSupport::Reloader.to_prepare do
  User.send(:include, UserPatch) unless User.included_modules.include? UserPatch
  Project.send(:include, ProjectPatch) unless Project.included_modules.include? ProjectPatch
end

gm = Redmine::Plugin.register :greenmachine do
  name 'Sassafras Green Machine'
  author 'Tom Smyth'
  description 'Sassafras Billing Plugin'
  version '1.1.1'
  url 'https://github.com/sassafrastech/greenmachine'
  author_url 'http://sassafras.coop/about'

  menu :top_menu, :polls, { controller: 'gm_reports', action: 'show' },
    caption: 'GreenMachine', if: -> (x) { GmUserInfo.can_view?(User.current) }
end

ActiveSupport::Dependencies.autoload_paths << "#{gm.directory}/app/models/concerns"

$qb_oauth_consumer = OAuth2::Client.new(QB_KEY, QB_SECRET,
  site: "https://appcenter.intuit.com/connect/oauth2",
  authorize_url: "https://appcenter.intuit.com/connect/oauth2",
  token_url: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
)
