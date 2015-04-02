class GmReportsController < ApplicationController
  unloadable

  before_filter :authorize, :build_interval

  def show
    @report = GmGridReport.new(interval: @interval)
    @report.run
  end

  def project_detail
    @project = Project.find(params[:project_id])
    @report = GmProjectDetailReport.new(interval: @interval, project: @project)
    @report.run
  end

  private

  def authorize
    unless GmUserType.can_view?(User.current)
      @error = "Unauthorized."
      render :show
    end
  end

  def build_interval
    begin
      params[:start] = params[:start] ? Date.parse(params[:start]) : Date.today.at_beginning_of_month
      params[:finish] = params[:finish] ? Date.parse(params[:finish]) : Date.today.at_end_of_month
    rescue ArgumentError
      @date_error = "Error parsing dates."
      return render :show
    end

    if params[:start] > params[:finish]
      @date_error = "Start date is after finish date."
      return render :show
    end

    @interval = GmInterval.new(start: params[:start], finish: params[:finish])
  end
end
