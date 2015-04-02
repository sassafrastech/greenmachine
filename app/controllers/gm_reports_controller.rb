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

    respond_to do |format|
      format.html
      format.csv do
        render_csv(filename: "#{@project.name.gsub(' ', '-').downcase}-timelog", content: @report.to_csv)
      end
    end
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

  def render_csv(options)
    filename = sanitize_filename("#{options[:filename]}.csv")

    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain"
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = "0"
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end

    render(text: options[:content])
  end

  # Removes any non-filename-safe characters from a string so that it can be used in a filename
  def sanitize_filename(filename)
    filename.strip.gsub(/[^0-9A-Za-z.\-]|\s/, '_')
  end
end
