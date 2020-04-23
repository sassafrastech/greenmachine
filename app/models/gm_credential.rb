class GmCredential < ActiveRecord::Base
  unloadable

  def apply_to(service)
    service.company_id = company_id
    service.access_token = access_token_instance
  end

  def access_token_instance
    @access_token_instance ||= OAuth2::AccessToken.new($qb_oauth_consumer, access_token)
  end

  def refresh!
    access_token_instance = OAuth2::AccessToken.new($qb_oauth_consumer, access_token, refresh_token: refresh_token)
    refreshed = access_token_instance.refresh!.to_hash
    self.access_token = refreshed[:access_token]
    self.refresh_token = refreshed[:refresh_token]
    self.token_expires_at = Time.zone.at(refreshed[:expires_at])
    save!
  end
end
