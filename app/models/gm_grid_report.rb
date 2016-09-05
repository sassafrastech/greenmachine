# Handles compilation of data for the main GreenMachine grid report.
class GmGridReport
  attr_accessor :interval, :chunk_data, :users, :projects, :chunks, :warnings, :project_rates,
    :user_types, :user_wage_rates, :totals, :summaries, :pto_proj, :internal_proj

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
    self.chunks = {revenue: {}, wage: {}}
    self.warnings = []
  end

  def run
    generate_chunk_data
    extract_users
    extract_projects
    check_chunks_for_issues
    build_chunks
    calculate_totals
    calculate_summaries
  end

  private

  # Run main SQL query to get hours per worker and project in the given time period.
  def generate_chunk_data
    self.chunk_data = TimeEntry.
      includes(:project, :user, :issue).
      select('user_id, project_id, issue_id, SUM(hours) AS hours').
      where('spent_on >= ?', interval.start).
      where('spent_on <= ?', interval.finish).
      group(:project_id, :user_id, :issue_id)
  end

  # Get all users included in chunk_data and sort by name.
  def extract_users
    self.users = chunk_data.map(&:user).uniq.sort_by(&:name)
    self.user_types = Hash[*users.map{ |u| [u, u.gm_info(interval)] }.flatten]

    no_type = users.select{ |u| user_types[u].nil? }
    self.users -= no_type
    unless no_type.empty?
      self.warnings << "The following users had hours but no user type: #{no_type.map(&:name).join(', ')}"
    end

    users.reject!{ |u| u.gm_info(interval).ignore? }

    no_rate = users.select{ |u| u.gm_wage_rate(interval).nil? }
    self.users -= no_rate
    unless no_rate.empty?
      self.warnings << "The following users had hours but no base wage rate: #{no_rate.map(&:name).join(', ')}"
    end

    no_pto_election = users.select{ |u| u.gm_info(interval).has_pto? && u.gm_pto_election(interval).nil? }
    self.users -= no_pto_election
    unless no_pto_election.empty?
      self.warnings << "The following users had hours but no PTO election: #{no_pto_election.map(&:name).join(', ')}"
    end
  end

  def check_chunks_for_issues
    projs = []
    chunk_data.each do |datum|
      projs << datum.project if datum.issue.blank?
    end
    projs.uniq!
    unless projs.empty?
      self.warnings << "The following projects had time entries with no associated issue: #{projs.map(&:name).join(', ')}"
    end
  end

  # Get all projects included in chunk_data and sort by name.
  def extract_projects
    self.projects = chunk_data.map(&:project).uniq.sort_by(&:name)

    # project_ids = chunk_data.map(&:project).map(&:id).uniq
    # # self.projects = GmProjectInfo.joins(:project).where(project_id: project_ids).order('projects.name')
    # self.projects = project_ids.map { |i| GmProjectInfo.find_or_create_by(project_id: i) }.sort_by(&:name)

    # Remove or catch special projects.
    self.pto_proj = projects.detect{ |p| p.name == 'Paid Time Off' }
    self.projects -= [pto_proj]

    self.internal_proj = projects.detect{ |p| p.name == 'Sassafras Internal' }

    # Ensure all projects have rates.
    self.project_rates = Hash[*projects.map{ |p| [p, p.gm_full_rate(interval)] }.flatten]

    no_rate = projects.select{ |p| project_rates[p].nil? }
    self.projects -= no_rate
    unless no_rate.empty?
      self.warnings << "The following projects had hours but no GM project rate: #{no_rate.map(&:name).join(', ')}"
    end
  end

  # Builds chunks (combinations of hour + rate) for revenue and wages.
  def build_chunks
    [:revenue, :wage].each do |type|
      chunk_data.each do |datum|
        datum_rate = GmRateFinder.find(type, interval,
          user: datum.user, project: datum.project, issue: datum.issue)
        if datum_rate
          chunks[type][[datum.user, datum.project]] ||= GmChunk.new
          chunks[type][[datum.user, datum.project]].add_entry(hours: datum.hours, rate: datum_rate)
        end
      end
    end
  end

  def calculate_totals
    self.totals = {revenue: {by_project: {}, by_user: {}}, wage: {by_project: {}, by_user: {}}}

    [:revenue, :wage].each do |type|

      # Project totals.
      projects.each do |p|
        totals[type][:by_project][p] = {hours: 0, dollars: 0}
        users.each do |u|
          if chunk = chunks[type][[u, p]]
            totals[type][:by_project][p][:hours] += chunk.hours
            totals[type][:by_project][p][:dollars] += chunk.dollars
          end
        end
      end

      # User totals.
      users.each do |u|
        totals[type][:by_user][u] = {hours: 0, dollars: 0}
        projects.each do |p|
          if chunk = chunks[type][[u, p]]
            totals[type][:by_user][u][:hours] += chunk.hours
            totals[type][:by_user][u][:dollars] += chunk.dollars
          end
        end
      end

      # Grand totals
      [:hours, :dollars].each do |measure|
        totals[type][measure] = totals[type][:by_user].values.sum{ |v| v[measure] }
      end
    end
  end

  def calculate_summaries
    self.summaries = {}

    summaries[:revenue] = GmSummary.new.tap do |s|
      users.each { |u| s[u] = totals[:revenue][:by_user][u][:dollars] }
    end

    summaries[:wage] = GmSummary.new.tap do |s|
      users.each { |u| s[u] = totals[:wage][:by_user][u][:dollars] }
    end

    summaries[:wage_rate] = GmSummary.new.tap do |s|
      users.each { |u| s[u] = u.gm_wage_rate(interval).val }
    end

    summaries[:rev_wage] = summaries[:revenue] / summaries[:wage]
    summaries[:rev_wage].total_type = :none
    summaries[:rev_wage].show_zero = true

    # PTO chunks still get generated even though not shown in main grid
    summaries[:pto_hours_claimed] = GmSummary.new.tap do |s|
      users.each { |u| s[u] = chunks[:wage][[u, pto_proj]].try(:hours) }
    end

    summaries[:pto_dollars_claimed] = summaries[:pto_hours_claimed] * summaries[:wage_rate]

    summaries[:wages_incl_pto] = summaries[:wage] + summaries[:pto_dollars_claimed]

    summaries[:pto_election] = GmSummary.new.tap do |s|
      users.each{ |u| s[u] = u.gm_pto_election(interval).try(:val) }
    end

    summaries[:gross_pto] = GmSummary.new.tap do |s|
      users.each{ |u| s[u] = u.gm_gross_pto(interval) }
    end

    summaries[:net_pto] = summaries[:gross_pto] - summaries[:pto_dollars_claimed]

    summaries[:health_insurance] = GmSummary.new.tap do |s|
      users.each{ |u| s[u] = u.gm_health_insurance(interval).try(:val) }
    end

    summaries[:payroll_tax] = GmSummary.new.tap do |s|
      users.each{ |u| s[u] = u.gm_info(interval).payroll_tax? ? summaries[:wage][u] * payroll_tax_rate : nil }
    end

    # Hours worked by internal folks.
    summaries[:worker_hours] = GmSummary.new.tap do |s|
      users.each{ |u| s[u] = u.gm_info(interval).internal? ? totals[:wage][:by_user][u][:hours] : nil }
    end

    summaries[:worker_hours_share] = summaries[:worker_hours] / summaries[:worker_hours].total

    summaries[:general_expenses_share] = summaries[:worker_hours_share] * general_expenses

    summaries[:total_expenses] = [:gross_pto, :health_insurance, :payroll_tax, :general_expenses_share].map{ |k| summaries[k]}.sum

    summaries[:surplus] = summaries[:revenue] - summaries[:total_expenses] - summaries[:wage]

    summaries[:rev_exp_wage] = summaries[:revenue] / (summaries[:total_expenses] + summaries[:wage])
    summaries[:rev_exp_wage].total_type = :none
    summaries[:rev_exp_wage].show_zero = true

    # Hours worked per day/week
    days_in_period = interval.finish - interval.start + 1
    weeks_in_period = days_in_period / 365 * 52
    summaries[:hours_per_week] = (summaries[:worker_hours] + summaries[:pto_hours_claimed]) / weeks_in_period
    summaries[:hours_per_week].total_type = :sum
    summaries[:hours_per_day] = summaries[:hours_per_week] / 5
    summaries[:hours_per_day].total_type = :sum
  end

  def payroll_tax_rate
    GmRateFinder.find('payroll_tax_pct', interval).try(:val).try(:/, 100) || 0
  end

  def general_expenses
    GmRateFinder.find('general_expenses', interval).try(:val) || 0
  end
end
