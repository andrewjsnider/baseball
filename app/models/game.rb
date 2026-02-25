class Game < ApplicationRecord
  belongs_to :team
  belongs_to :opponent_team, class_name: "Team", optional: true

  has_one :lineup, dependent: :destroy
  has_many :pitch_appearances, dependent: :destroy

  validates :date, presence: true
end
