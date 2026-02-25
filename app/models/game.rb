class Game < ApplicationRecord
  belongs_to :team
  belongs_to :opponent_team, class_name: "Team", optional: true

  has_one :lineup, dependent: :destroy
  has_many :game_pitch_plan_slots, dependent: :destroy
  has_many :pitch_appearances, dependent: :destroy

  validates :date, presence: true

  def ensure_pitch_plan_slots!
    GamePitchPlanSlot::ROLES.values.sort.each do |role_int|
      game_pitch_plan_slots.find_or_create_by!(role: role_int)
    end
  end
end
