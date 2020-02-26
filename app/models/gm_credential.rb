class GmCredential < ActiveRecord::Base
  unloadable

  def apply_to(service)
    service.company_id = company_id
    service.access_token = access_token
  end

  def access_token
    @access_token ||= OAuth2::AccessToken.new($qb_oauth_consumer, token)
  end
end
