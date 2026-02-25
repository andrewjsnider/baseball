class PitchAppearance < ApplicationRecord
  belongs_to :player
  belongs_to :game

  validates :pitches_thrown, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :player_id, uniqueness: { scope: :game_id }
end
