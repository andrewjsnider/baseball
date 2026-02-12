class LineupSlot < ApplicationRecord
  belongs_to :lineup
  belongs_to :player

  enum :field_position, {
    pitcher: 0,
    catcher: 1,
    first_base: 2,
    second_base: 3,
    third_base: 4,
    shortstop: 5,
    left_field: 6,
    center_field: 7,
    right_field: 8,
    bench: 9
  }

  validates :batting_order, presence: true
end
