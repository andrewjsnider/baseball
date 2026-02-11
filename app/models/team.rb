class Team < ApplicationRecord
  has_many :players

  def pitchers_count
    players.where(primary_position: "P").count
  end

  def catchers_count
    players.where(primary_position: "C").count
  end

  def infield_count
    players.where(primary_position: %w[SS 2B 3B 1B]).count
  end

  def outfield_count
    players.where(primary_position: "OF").count
  end
end
