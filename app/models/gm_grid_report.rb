# Handles compilation of data for the main GreenMachine grid report.
class GmGridReport
  attr_accessor :interval, :chunk_data, :users, :projects, :chunks, :warnings, :project_rates, :user_types,
   :totals

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

    no_type = users.select{ |u| user_types[u].nil? }
    self.users -= no_type
    unless no_type.empty?
      self.warnings << "The following users had hours but no GM user type: #{no_type.map(&:name).join(', ')}"
    end
  end

  # Get all projects included in chunk_data and sort by name.
  def extract_projects
    self.projects = chunk_data.map(&:project).uniq.sort_by(&:name)
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
      chunk_data.each do |total|
        rate = total.user.gm_rate(type, total.project, interval)
        chunks[type][[total.user, total.project]] = GmChunk.new(hours: total.hours, rate: rate)
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
    end
  end
end
