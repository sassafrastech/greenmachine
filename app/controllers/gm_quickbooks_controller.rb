class GmQuickbooksController < ApplicationController
  unloadable

  def authenticate
    callback = gm_quickbooks_callback_url
    token = $qb_oauth_consumer.get_request_token(oauth_callback: callback)
    session[:qb_request_token] = token
    redirect_to("https://appcenter.intuit.com/Connect/Begin?oauth_token=#{token.token}") and return
  end

  def callback
    access_token = session[:qb_request_token].get_access_token(oauth_verifier: params[:oauth_verifier])
    GmCredential.delete_all
    GmCredential.create(token: access_token.token, secret: access_token.secret, company_id: params['realmId'])
  end
end