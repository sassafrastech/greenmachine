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

        # We multiply the hours by the ratio of the user's rate for the project to the full rate for the project.
        hours = datums.map do |d|
          full_rate = project.gm_full_rate(interval).val
          adjustment_factor = full_rate == 0 ? 1 : (d.user.gm_project_rate(project, interval).val / full_rate)
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

