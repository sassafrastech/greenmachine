class GmConfigController < GmApplicationController
  unloadable

  before_filter :authorize

  def index
  end

end
