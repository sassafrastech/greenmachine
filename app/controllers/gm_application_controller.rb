class GmApplicationController < ApplicationController
  def authorize
    unless GmUserInfo.can_view?(User.current)
      @error = "Unauthorized."
      render 'gm_reports/show'
    end
  end

end
