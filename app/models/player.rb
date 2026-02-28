class Player < ApplicationRecord
  TIERS = %w[A B C].freeze

  belongs_to :team, optional: true

  has_many :player_days, dependent: :destroy
  has_many :player_positions, dependent: :destroy
  has_many :pitch_appearances, dependent: :destroy
  has_many :positions, through: :player_positions

  include Player::Draftable
  include Player::Evaluation
  include Player::PitchingEligibility
  include Player::Positions

  validates :name, presence: true
  validates :tier, inclusion: { in: TIERS }, allow_nil: true

  validates :baseball_iq,
            :arm_strength,
            :arm_accuracy,
            :pitching_control,
            :pitching_velocity,
            :catching_rating,
            :speed,
            :fielding,
            :hitting_contact,
            :hitting_power,
            :coachability,
            :parent_reliability,
            numericality: { only_integer: true, in: 1..5 },
            allow_nil: true

  validates :confidence_level,
            numericality: { only_integer: true, in: 1..5 },
            allow_nil: true

  scope :available, -> { where(team_id: nil, drafted: false, draftable: true) }

  scope :eval_fields_filled_count_lt, ->(n) {
    fields = %w[
      pitching_rating hitting_rating infield_defense_rating outfield_defense_rating speed
    ]

    expr = fields.map { |f| "CASE WHEN #{f} IS NULL THEN 0 ELSE 1 END" }.join(" + ")
    where("(#{expr}) < ?", n)
  }

  def player_day_for(date)
    player_days.find_or_create_by!(date: date)
  end
end
