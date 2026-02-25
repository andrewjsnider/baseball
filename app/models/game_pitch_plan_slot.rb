class GamePitchPlanSlot < ApplicationRecord
  ROLES = {
    starter: 0,
    relief_1: 1,
    relief_2: 2,
    relief_3: 3,
    emergency: 4
  }.freeze

  belongs_to :game
  belongs_to :player, optional: true

  enum :role, ROLES

  validates :target_pitches, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :game_id, uniqueness: { scope: :role }
end