class Team < ApplicationRecord
  ROSTER_SIZE = 13
  TARGET_PITCHERS = 6
  TARGET_CATCHERS = 2
  TARGET_SHORT_STOP = 2

  NAMES = %w[Giants Marlins Mariners Phillies Dodgers Padres].freeze
  has_many :players

   def roster_count
    players.count
  end

  def spots_remaining
    ROSTER_SIZE - roster_count
  end

   def pitchers_needed
    [TARGET_PITCHERS - pitchers_count, 0].max
  end

  def catchers_needed
    [TARGET_CATCHERS - catchers_count, 0].max
  end

  def short_stops_needed
    [TARGET_SHORT_STOP - short_stops_count, 0].max
  end

  def pitchers_count
    players.joins(:positions).where(positions: { name: "P" }).distinct.count
  end

  def catchers_count
    players.joins(:positions).where(positions: { name: "C" }).distinct.count
  end

  def short_stops_count
    players.joins(:positions).where(positions: { name: ["SS"] }).distinct.count
  end

  def outfield_count
    players.joins(:positions).where(positions: { name: ["OF"] }).distinct.count
  end

  def roster_count
    players.count
  end

  def spots_remaining
    ROSTER_SIZE - roster_count
  end

  def picks_until_next_turn(total_teams)
    total_teams - 1
  end
end
