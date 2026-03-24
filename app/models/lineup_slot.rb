class LineupSlot < ApplicationRecord
  belongs_to :lineup
  belongs_to :player

  POSITIONS = {
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
  }.freeze

  enum :field_position, POSITIONS
  enum :field_position_first_two, POSITIONS, prefix: :first_two
  enum :field_position_second_two, POSITIONS, prefix: :second_two

  validates :batting_order, presence: true

  POSITION_ABBREVIATIONS = {
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
  }.freeze

  def field_position_abbreviation
    POSITION_ABBREVIATIONS[field_position]
  end

  def first_two_abbreviation
    POSITION_ABBREVIATIONS[field_position_first_two]
  end

  def second_two_abbreviation
    POSITION_ABBREVIATIONS[field_position_second_two]
  end

  def first_two_field_innings
    return 0 if field_position_first_two.blank?
    return 0 if field_position_first_two == "extra_hitter"
    2
  end

  def second_two_field_innings
    return 0 if field_position_second_two.blank?
    return 0 if field_position_second_two == "extra_hitter"
    2
  end

  def field_innings_count
    first_two_field_innings + second_two_field_innings
  end
end
