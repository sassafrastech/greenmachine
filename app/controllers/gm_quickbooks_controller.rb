class GmQuickbooksController < ApplicationController
  unloadable

  def authenticate
    callback = gm_quickbooks_callback_url
    token = $qb_oauth_consumer.get_request_token(oauth_callback: callback)
    session[:qb_request_token] = token
    grant_url = $qb_oauth_consumer.auth_code.authorize_url(
      redirect_uri: callback,
      state: SecureRandom.hex(12),
      scope: "com.intuit.quickbooks.accounting"
    )
    redirect_to grant_url
  end

  def callback
    if params[:state]
      response = $qb_oauth_consumer.auth_code.get_token(params[:code], redirect_uri: gm_quickbooks_callback_url)
      if response
        GmCredential.delete_all
        GmCredential.create(
          token: response.token,
          secret: response.refresh_token,
          # token_expires_at: Time.zone.at(response.expires_at),
          company_id: params['realmId']
        )
      end
    end
  end
end
