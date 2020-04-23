class GmCredential < ActiveRecord::Base
  unloadable

  def apply_to(service)
    service.company_id = company_id
    service.access_token = access_token_instance
  end

  def access_token_instance
    @access_token_instance ||= OAuth2::AccessToken.new($qb_oauth_consumer, access_token)
  end
end
