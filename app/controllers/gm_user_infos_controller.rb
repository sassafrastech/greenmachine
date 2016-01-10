class GmUserInfosController < GmApplicationController
  unloadable
  before_filter :authorize
  before_action :set_gm_user_info, only: [:show, :edit, :update, :destroy]

  # GET /gm_user_infos
  def index
    @gm_user_infos = GmUserInfo.joins(:user).order('users.firstname, effective_on')
  end

  # GET /gm_user_infos/1
  def show
  end

  # GET /gm_user_infos/new
  def new
    @gm_user_info = GmUserInfo.new
  end

  # GET /gm_user_infos/1/edit
  def edit
  end

  # POST /gm_user_infos
  def create
    @gm_user_info = GmUserInfo.new(gm_user_info_params)

    if @gm_user_info.save
      redirect_to @gm_user_info, notice: 'GM user record was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /gm_user_infos/1
  def update
    if @gm_user_info.update(gm_user_info_params)
      redirect_to @gm_user_info, notice: 'GM user record was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /gm_user_infos/1
  def destroy
    @gm_user_info.destroy
    redirect_to gm_user_infos_url, notice: 'GM user record was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gm_user_info
      @gm_user_info = GmUserInfo.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def gm_user_info_params
      params.require(:gm_user_info).permit(:user_id, :effective_on, :user_type)
    end
end
