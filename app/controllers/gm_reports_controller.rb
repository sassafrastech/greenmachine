class GmReportsController < GmApplicationController
  unloadable

  before_action :authorize, :build_interval

  def show
    @report = GmGridReport.new(interval: @interval)
    @report.run
  end

  def project_detail
    build_project_report

    respond_to do |format|
      format.html
      format.csv do
        filename = sanitize_filename(@report.csv_filename)
        headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
        render(body: @report.to_csv, content_type: "text/csv")
      end
    end
  end

  def create_invoice
    build_project_report

    credential = GmCredential.first

    @no_token = true and return unless credential

    begin
      credential.refresh! if credential.token_expires_at < Time.zone.now
    rescue
      @auth_fail = true and return
    end

    begin
      @creator = GmInvoiceCreator.new(report: @report, credential: credential)
      @invoice = @creator.create
    rescue Quickbooks::AuthorizationFailure
      @auth_fail = true
    end
  end

  private

  def build_interval
    if params[:month] == :last
      params[:start] = Date.today.at_beginning_of_month - 1.month
      params[:finish] = params[:start].at_end_of_month
    else
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
    end

    @interval = GmInterval.new(start: params[:start], finish: params[:finish])
  end

  def build_project_report
    @project = Project.find(params[:project_id])
    @category = params[:category_id] ? IssueCategory.find(params[:category_id]) : nil
    @report = GmProjectDetailReport.new(interval: @interval, project: @project, category: @category)
    @report.run
  end

  # Removes any non-filename-safe characters from a string so that it can be used in a filename
  def sanitize_filename(filename)
    filename.strip.gsub(/[^0-9A-Za-z.\-]|\s/, '_')
  end
end
