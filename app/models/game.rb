class Game < ApplicationRecord
  belongs_to :team
  has_one :lineup, dependent: :destroy
  has_many :pitch_appearances, dependent: :destroy

  validates :date, presence: true
end
