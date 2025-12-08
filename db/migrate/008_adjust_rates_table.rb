class AdjustRatesTable < ActiveRecord::Migration[4.2]
  def up
    add_column(:gm_rates, :user_type, :string)
    add_index(:gm_rates, :user_type)
    execute("UPDATE gm_rates SET
      user_type = IF(kind = 'member_wage_base', 'member', NULL),
      kind = IF(kind LIKE '%wage%', 'wage', IF(kind LIKE '%revenue%', 'revenue', kind))")
  end
end
