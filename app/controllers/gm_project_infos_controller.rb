class GmProjectInfosController < ApplicationController
  before_action :set_gm_project_info, only: [:show, :edit, :update, :destroy]

  # GET /gm_project_infos
  def index
    @gm_project_infos = GmProjectInfo.all
  end

  # GET /gm_project_infos/1
  def show
  end

  # GET /gm_project_infos/new
  def new
    @gm_project_info = GmProjectInfo.new
  end

  # GET /gm_project_infos/1/edit
  def edit
  end

  # POST /gm_project_infos
  def create
    @gm_project_info = GmProjectInfo.new(gm_project_info_params)

    if @gm_project_info.save
      redirect_to @gm_project_info, notice: 'Gm project info was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /gm_project_infos/1
  def update
    if @gm_project_info.update(gm_project_info_params)
      redirect_to @gm_project_info, notice: 'Gm project info was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /gm_project_infos/1
  def destroy
    @gm_project_info.destroy
    redirect_to gm_project_infos_url, notice: 'Gm project info was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gm_project_info
      @gm_project_info = GmProjectInfo.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def gm_project_info_params
      params.require(:gm_project_info).permit(:project_id, :gm_qb_customer_id, :gm_extra_emails)
    end
end
