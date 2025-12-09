# Patches to the Redmine core.
require_relative 'lib/user_patch'
require_relative 'lib/project_patch'

require_relative 'config/initializers/quickbooks'

gm = Redmine::Plugin.register :greenmachine do
  name 'Sassafras Green Machine'
  author 'Tom Smyth'
  description 'Sassafras Billing Plugin'
  version '1.1.1'
  url 'https://github.com/sassafrastech/greenmachine'
  author_url 'https://sassafras.coop/about'

  menu :top_menu, :polls, { controller: 'gm_reports', action: 'show' },
    caption: 'GreenMachine', if: -> (x) { GmUserInfo.can_view?(User.current) }
end

$qb_oauth_consumer = OAuth2::Client.new(Secrets::QB_KEY, Secrets::QB_SECRET,
  site: "https://appcenter.intuit.com/connect/oauth2",
  authorize_url: "https://appcenter.intuit.com/connect/oauth2",
  token_url: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
)
