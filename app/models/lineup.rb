class Lineup < ApplicationRecord
  belongs_to :game
  belongs_to :starting_pitcher, class_name: "Player", optional: true

  has_many :lineup_slots, -> { order(:batting_order) }, dependent: :destroy

  accepts_nested_attributes_for :lineup_slots
end
