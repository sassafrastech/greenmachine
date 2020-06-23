# Computes data on issues adjust numbers of hours per issue.
require 'csv'

class GmProjectDetailReport
  attr_accessor :interval, :project, :category, :chunk_data, :chunk_groups, :totals

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
      csv << ['Source', 'Issue', 'Billed Hours']

      chunk_groups.each do |user, chunks|
        csv << [user == :sassy ? 'Sassafras' : user.name]
        chunks.each do |chunk|
          csv << ['', "#{chunk.issue.tracker.name} ##{chunk.issue.id}: #{chunk.issue.subject}",
            chunk.rounded_billed_hours]
        end
        csv << ['', "Total", totals[user]]
      end
    end
  end

  def csv_filename
    "#{project.name.gsub(' ', '-').downcase}-timelog.csv"
  end

  private

  # Run main SQL query to get hours per worker in the given time period.
  def generate_chunk_data
    query = TimeEntry.
      select('user_id, issue_id, activity_id, SUM(hours) AS hours').
      joins(:issue, :user).
      where(project_id: project.id).
      where('spent_on >= ?', interval.start).
      where('spent_on <= ?', interval.finish).
      where('activity_id != ?', GmChunk::UNBILLED_UNPAID_ACTIVITY_ID).
      group(:user_id, :issue_id, :activity_id).
      order('issues.subject')

    query = query.where('issues.category_id = ?', category.id) if category

    self.chunk_data = query.to_a
  end

  def build_chunks
    self.chunk_groups = {}

    # Remove any data for users with no type.
    chunk_data.reject!{ |d| d.user.gm_info(interval).nil? }

    # Group the data by user, or :sassy if internal.
    subsets = chunk_data.group_by{ |d| d.user.gm_info(interval).internal? ? :sassy : d.user }

    # Build the chunks by summing the data.
    chunk_groups[:sassy] = build_chunks_for_subset(:sassy, subsets.delete(:sassy) || [])
    subsets.each{ |user, subset| chunk_groups[user] = build_chunks_for_subset(user, subset) }
  end

  def build_chunks_for_subset(user, subset)
    [].tap do |chunks|
      # The subset rate is the project full rate for sassy, and the user project rate otherwise.
      subset_rate = user == :sassy ? project.gm_full_rate(interval).val : user.gm_project_rate(project, interval).val

      # A subset is a set of (issue, user, hours) tuples. We want to aggregate by issue, summing the hours.
      subset.group_by(&:issue).each do |issue, datums|
        hours = datums.map do |d|
          is_unbilled = d.activity_id == GmChunk::UNBILLED_ACTIVITY_ID
          adjustment_factor = if subset_rate == 0
                                0 # Don't div by 0.

                              # Ignore unbilled for this report.
                              elsif is_unbilled
                                0

                              # If user has a special issue rate, compare that against the subset rate.
                              elsif user_issue_rate = d.user.gm_issue_rate(issue, interval).try(:val)
                                user_issue_rate / subset_rate

                              # Otherwise if this is sassy, factor is user project rate compared to full rate.
                              # (For contractors, the subset_rate /is/ the project rate)
                              elsif user == :sassy
                                d.user.gm_project_rate(project, interval).val / subset_rate

                              # Otherwise there is no need to adjust.
                              else
                                1
                              end

          d.hours * adjustment_factor
        end.sum

        chunk = GmChunk.new(issue: issue, hours: hours)
        chunks << chunk
      end
    end
  end

  def calculate_totals
    self.totals = Hash[*chunk_groups.map{ |u, chunks| [u, chunks.sum(&:rounded_billed_hours)] }.flatten]
  end
end
