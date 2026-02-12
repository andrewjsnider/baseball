class LineupsController < ApplicationController
  before_action :set_lineup

  def show
    @players = @lineup.game.team.players
  end

  def update_order
    params[:player_ids].each_with_index do |player_id, index|
      spot = @lineup.lineup_spots.find_or_initialize_by(player_id: player_id)
      spot.update!(batting_order: index + 1)
    end

    head :ok
  end

  private

  def set_lineup
    @lineup = Lineup.find(params[:id])
  end
end
