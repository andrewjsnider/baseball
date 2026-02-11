class Team < ApplicationRecord
  ROSTER_SIZE = 12
  NAMES = %w[Giants Marlins Braves Phillies Dodgers Padres Diamondbacks].freeze
  has_many :players

  def pitchers_count
    players.joins(:positions).where(positions: { name: "P" }).distinct.count
  end

  def catchers_count
    players.joins(:positions).where(positions: { name: "C" }).distinct.count
  end

  def middle_infield_count
    players.joins(:positions).where(positions: { name: ["SS", "2B"] }).distinct.count
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
