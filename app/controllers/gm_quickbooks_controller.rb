class GmQuickbooksController < ApplicationController
  unloadable

  def authenticate
    callback = gm_quickbooks_callback_url
    grant_url = $qb_oauth_consumer.auth_code.authorize_url(
      redirect_uri: callback,
      state: SecureRandom.hex(12),
      scope: "com.intuit.quickbooks.accounting"
    )
    redirect_to grant_url
  end

  def callback
    if params[:state]
      callback = gm_quickbooks_callback_url
      response = $qb_oauth_consumer.auth_code.get_token(params[:code], redirect_uri: callback)
      if response
        GmCredential.delete_all
        GmCredential.create(
          access_token: response.token,
          refresh_token: response.refresh_token,
          token_expires_at: Time.zone.at(response.expires_at),
          company_id: params['realmId']
        )
      end
    end
  end
end
