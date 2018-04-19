class GmRatesController < GmApplicationController
  unloadable
  before_filter :authorize
  before_action :set_gm_rate, only: [:show, :edit, :update, :destroy]

  # GET /gm_rates
  def index
    @gm_rates = GmRate.order('effective_on desc, id desc')
  end

  # GET /gm_rates/1
  def show
  end

  # GET /gm_rates/new
  def new
    @gm_rate = GmRate.new
  end

  # GET /gm_rates/1/edit
  def edit
  end

  # POST /gm_rates
  def create
    @gm_rate = GmRate.new(gm_rate_params)

    if @gm_rate.save
      redirect_to @gm_rate, notice: 'Rate was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /gm_rates/1
  def update
    if @gm_rate.update(gm_rate_params)
      redirect_to @gm_rate, notice: 'Rate was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /gm_rates/1
  def destroy
    @gm_rate.destroy
    redirect_to gm_rates_url, notice: 'Rate was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gm_rate
      @gm_rate = GmRate.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def gm_rate_params
      params.require(:gm_rate).permit(*%i(kind user_id user_type project_id issue_id val effective_on))
    end
end
