class LineupSpot < ApplicationRecord
  belongs_to :lineup
  belongs_to :player

  validates :batting_order, presence: true
  validates :player_id, uniqueness: { scope: :lineup_id }
end
