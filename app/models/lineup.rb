class Lineup < ApplicationRecord
  belongs_to :game
  has_many :lineup_spots, dependent: :destroy

  def ordered_spots
    lineup_spots.order(:batting_order)
  end
end
