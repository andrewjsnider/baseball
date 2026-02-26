class PitchAppearancesController < ApplicationController
  def create
    game = Game.find(params[:game_id])
    pa = PitchAppearance.find_or_create_by!(game_id: game.id, player_id: params[:player_id])
    pa.update!(pitches_thrown: pa.pitches_thrown.to_i)
    redirect_to game_path(game)
  end

  def update
    @game = Game.find(params[:game_id])
    @player = @game.team.players.find(params[:id])

    pa = PitchAppearance.find_or_create_by!(game_id: @game.id, player_id: @player.id)

    delta = params[:delta].to_i
    new_val = [pa.pitches_thrown.to_i + delta, 0].max
    pa.update!(pitches_thrown: new_val)

    @show = GameShowPresenter.new(game: @game)
    row = @show.pitcher_rows.find { |r| r.player.id == @player.id }

    respond_to do |format|
      format.html { redirect_to game_path(@game) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@game, "pitch_counter_player_#{@player.id}"),
          partial: "games/pitch_counter_row",
          locals: { game: @game, row: row }
        )
      end
    end
  end
end
