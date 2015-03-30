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
