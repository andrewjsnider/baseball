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
    extra_hitter: 9
  }

  validates :batting_order, presence: true

  def field_position_abbreviation
    {
      "pitcher" => "P",
      "catcher" => "C",
      "first_base" => "1B",
      "second_base" => "2B",
      "third_base" => "3B",
      "shortstop" => "SS",
      "left_field" => "LF",
      "center_field" => "CF",
      "right_field" => "RF",
      "extra_hitter" => "EH"
    }[field_position]
  end
end
