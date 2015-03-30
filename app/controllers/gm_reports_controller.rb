class GmReportsController < ApplicationController
  unloadable

  def show
    begin
      params[:start] = params[:start] ? Date.parse(params[:start]) : Date.today.at_beginning_of_month
      params[:finish] = params[:finish] ? Date.parse(params[:finish]) : Date.today.at_end_of_month
    rescue ArgumentError
      @error = "Error parsing dates."
      return
    end

    return @error = "Start date is after finish date." if params[:start] > params[:finish]
  end
end
