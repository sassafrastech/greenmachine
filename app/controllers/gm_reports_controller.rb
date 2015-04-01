class GmReportsController < ApplicationController
  unloadable

  def show
    return @error = "Unauthorized." unless GmUserType.can_view?(User.current)

    begin
      params[:start] = params[:start] ? Date.parse(params[:start]) : Date.today.at_beginning_of_month
      params[:finish] = params[:finish] ? Date.parse(params[:finish]) : Date.today.at_end_of_month
    rescue ArgumentError
      @date_error = "Error parsing dates."
      return
    end

    return @date_error = "Start date is after finish date." if params[:start] > params[:finish]

    @report = GmGridReport.new(interval: GmInterval.new(start: params[:start], finish: params[:finish]))
    @report.run
  end
end
