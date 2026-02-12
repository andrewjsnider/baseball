class PitchAppearance < ApplicationRecord
  belongs_to :player
  belongs_to :game

  validates :pitches_thrown, presence: true
end
