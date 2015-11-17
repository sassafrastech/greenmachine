# Finds GmRates applicable to given combinations of kind, interval, project, and issue
# Let t = user type, u = user, p = project, and i = issue.
# Then rates are chosen in this priority (lowest to highest):
#
# {t}
# {u}
# {p}
# {p, t}
# {p, u}
# {i}
# {i, t}
# {i, u}
#
# e.g. a rate specifying a project and user is lower priority than a rate that specifies a specific issue.
# This is equivalent to lexographic ordering with the following ordering: t < u < p < i
class GmRateFinder
  def self.find(kind, interval, params = {})

    rates = GmRate.applicable_to(interval).where(kind: kind)

    if params[:user].present?
      rates = rates.where("user_id IS NULL OR user_id = ?", params[:user].id)
      rates = rates.where("user_type IS NULL OR user_type = ?", params[:user].gm_user_type(interval))
    else
      rates = rates.where("user_id IS NULL").where("user_type IS NULL")
    end

    if params[:project].present?
      rates = rates.where("project_id IS NULL OR project_id = ?", params[:project].id)
    else
      rates = rates.where("project_id IS NULL")
    end

    if params[:issue].present?
      rates = rates.where("issue_id IS NULL OR issue_id = ?", params[:issue].id)
    else
      rates = rates.where("issue_id IS NULL")
    end

    # Group by sort code, e.g. 0101 for {i, u} above (see GmRate class)
    rates_by_code = rates.group_by(&:sort_code)

    # Get most recent rate for each set
    rates = rates_by_code.map{ |_, rs| rs.last }

    # Remove any cancellations
    rates.reject!(&:cancellation?)

    # Take the highest sorted rate (may be nil if no rates left)
    rates.sort_by(&:sort_code).last
  end
end
