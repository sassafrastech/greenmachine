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
    build_chunks
    calculate_totals
    calculate_summaries
  end

  private

  # Run main SQL query to get hours per worker and project in the given time period.
  def generate_chunk_data
    self.chunk_data = TimeEntry.
      includes(:project, :user).
      select('user_id, project_id, SUM(hours) AS hours').
      where('spent_on >= ?', interval.start).
      where('spent_on <= ?', interval.finish).
      group(:project_id, :user_id)
  end

  # Get all users included in chunk_data and sort by name.
  def extract_users
    self.users = chunk_data.map(&:user).uniq.sort_by(&:name)
    self.user_types = Hash[*users.map{ |u| [u, u.gm_type(interval)] }.flatten]
    self.user_wage_rates = Hash[*users.map{ |u| [u, u.gm_wage_rate(interval)] }.flatten]

    no_type = users.select{ |u| user_types[u].nil? }
    self.users -= no_type
    unless no_type.empty?
      self.warnings << "The following users had hours but no user type: #{no_type.map(&:name).join(', ')}"
    end

    no_rate = users.select{ |u| user_wage_rates[u].nil? }
    self.users -= no_rate
    unless no_rate.empty?
      self.warnings << "The following users had hours but no base wage rate: #{no_rate.map(&:name).join(', ')}"
    end

    no_pto_election = users.select{ |u| u.gm_type(interval).has_pto? && u.gm_pto_election(interval).nil? }
    self.users -= no_pto_election
    unless no_pto_election.empty?
      self.warnings << "The following users had hours but no PTO election: #{no_pto_election.map(&:name).join(', ')}"
    end
  end

  # Get all projects included in chunk_data and sort by name.
  def extract_projects
    self.projects = chunk_data.map(&:project).uniq.sort_by(&:name)

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
        if type == :revenue
          rate = datum.user.gm_project_rate(datum.project, interval)
        else
          rate = user_wage_rates[datum.user] # This is guaranteed to exist at this point.
        end

        chunks[type][[datum.user, datum.project]] = GmChunk.new(hours: datum.hours, rate: rate)
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

    # Rev/wage
    summary = GmSummary.new(total_type: :average)
    users.each do |u|
      rev = totals[:revenue][:by_user][u][:dollars]
      wage = totals[:wage][:by_user][u][:dollars]
      summary.by_user[u] = wage == 0 ? 0 : rev / wage
    end
    summaries[:rev_wage] = summary

    # PTO election
    summary = GmSummary.new
    users.each{ |u| summary.by_user[u] = u.gm_pto_election(interval).try(:val) }
    summaries[:pto_election] = summary

    # Gross PTO
    summary = GmSummary.new
    users.each{ |u| summary.by_user[u] = u.gm_gross_pto(interval) }
    summaries[:gross_pto] = summary

    # PTO Claimed (PTO chunks still get generated even though not shown in main grid)
    summary = GmSummary.new
    users.each{ |u| summary.by_user[u] = chunks[:wage][[u, pto_proj]].try(:hours) }
    summaries[:pto_claimed] = summary

    # Net PTO
    summary = GmSummary.new
    users.each do |u|
      claimed_hours = summaries[:pto_claimed].by_user[u] || 0
      claimed_dollars = claimed_hours * u.gm_wage_rate(interval).val
      summary.by_user[u] = (summaries[:gross_pto].by_user[u] || 0) - claimed_dollars
    end
    summaries[:net_pto] = summary

    # Wages inlcuding PTO
    summary = GmSummary.new
    users.each do |u|
      summary.by_user[u] = totals[:wage][:by_user][u][:dollars] +
        (summaries[:pto_claimed].by_user[u] || 0) * u.gm_wage_rate(interval).val
    end
    summaries[:wages_incl_pto] = summary
  end
end
