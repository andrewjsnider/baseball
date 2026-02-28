class PitchAppearance < ApplicationRecord
  belongs_to :player
  belongs_to :game

  validates :pitches_thrown, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :pitched_on, presence: true

  validates :player_id, uniqueness: { scope: [:game_id, :pitched_on] }

  scope :with_pitches, -> { where("pitches_thrown IS NOT NULL AND pitches_thrown > 0") }
end
