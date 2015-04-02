# Computes data on issues adjust numbers of hours per issue.
class GmProjectDetailReport
  attr_accessor :interval, :project, :chunk_data, :chunk_groups, :totals

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def run
    generate_chunk_data
    build_chunks
    calculate_totals
  end

  # Assumes report has already been run.
  def to_csv
    CSV.generate do |csv|
      # Header row.
      csv << ['Source', 'Issue', 'Hours']

      chunk_groups.each do |user, chunks|
        csv << [user == :sassy ? 'Sassafras' : user.name]
        chunks.each do |chunk|
          rounded_hours = (chunk.hours * 100).ceil.to_f / 100.0 # Round up to next hundredth to avoid 0.00
          csv << ['', "#{chunk.issue.tracker.name} ##{chunk.issue.id}: #{chunk.issue.subject}", rounded_hours]
        end
        csv << ['', "Total", totals[user].round(2)]
      end
    end
  end

  def csv_filename
    "#{project.name.gsub(' ', '-').downcase}-timelog.csv"
  end

  private

  # Run main SQL query to get hours per worker in the given time period.
  def generate_chunk_data
    self.chunk_data = TimeEntry.
      select('user_id, issue_id, SUM(hours) AS hours').
      joins(:issue, :user).
      where(project_id: project.id).
      where('spent_on >= ?', interval.start).
      where('spent_on <= ?', interval.finish).
      group(:user_id, :issue_id).
      order('issues.subject')
  end

  def build_chunks
    self.chunk_groups = {}

    # Remove any data for users with no type.
    chunk_data.reject!{ |d| d.user.gm_type(interval).nil? }

    # Group the data by user, or :sassy if internal.
    subsets = chunk_data.group_by{ |d| d.user.gm_type(interval).internal? ? :sassy : d.user }

    # Build the chunks by summing the data.
    chunk_groups[:sassy] = build_chunks_for_subset(subsets.delete(:sassy) || [])
    subsets.each{ |user, subset| chunk_groups[user] = build_chunks_for_subset(subset) }
  end

  def build_chunks_for_subset(subset)
    [].tap do |chunks|
      # A subset is a set of (issue, user, hours) tuples. We want to aggregate by issue, summing the hours.
      subset.group_by(&:issue).each do |issue, datums|

        # For internal users, we multiply the hours by the ratio of the user's rate for the project to the full rate for the project.
        hours = datums.map do |d|
          full_rate = project.gm_full_rate(interval).val
          adjustment_factor = if full_rate == 0
            0
          elsif !d.user.gm_type(interval).internal?
            1
          else
            d.user.gm_project_rate(project, interval).val / full_rate
          end
          d.hours * adjustment_factor
        end.sum

        chunks << GmChunk.new(issue: issue, hours: hours)
      end
    end
  end

  def calculate_totals
    self.totals = Hash[*chunk_groups.map{ |u, chunks| [u, chunks.sum(&:hours)] }.flatten]
  end
end

