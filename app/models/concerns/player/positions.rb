module Player::Positions
  extend ActiveSupport::Concern

  def plays_position?(name)
    positions.any? { |p| p.name == name }
  end

  def pitch_candidate?
    can_pitch || plays_position?("P") || pitching_rating.to_i >= 3
  end

  def catch_candidate?
    can_catch || plays_position?("C") || catching_rating.to_i >= 3
  end

  class_methods do
    def position_scarcity
      Position.all.each_with_object({}) do |position, hash|
        count = position.players.where(team_id: nil).distinct.count
        hash[position.name] = count
      end.sort_by { |_, count| count }.to_h
    end

    def positional_dropoff(position_name)
      available = Player.where(team_id: nil)
                        .select { |p| p.plays_position?(position_name) }
                        .sort_by { |p| -p.overall_score.to_f }

      return 0 if available.size < 2

      top = available[0].overall_score.to_f
      second = available[1].overall_score.to_f
      top - second
    end

    def top_player_for(position_name)
      Player.where(team_id: nil)
            .joins(:positions)
            .where(positions: { name: position_name })
            .distinct
            .max_by { |p| p.overall_score.to_f }
    end
  end
end