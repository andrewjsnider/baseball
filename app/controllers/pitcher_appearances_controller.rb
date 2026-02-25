class PitcherAppearancesController < ApplicationController
    def create
    game = Game.find(params[:game_id])
    pa = PitchAppearance.find_or_create_by!(game_id: game.id, player_id: params[:player_id])
    pa.update!(pitches_thrown: pa.pitches_thrown.to_i)
    redirect_to game_path(game)
  end

  def update
    game = Game.find(params[:game_id])
    pa = PitchAppearance.find_or_create_by!(game_id: game.id, player_id: params[:id])

    delta = params[:delta].to_i
    new_val = [pa.pitches_thrown.to_i + delta, 0].max
    pa.update!(pitches_thrown: new_val)

    respond_to do |format|
      format.html { redirect_to game_path(game) }
      format.turbo_stream
    end
  end
end
