class PitchAppearancesController < ApplicationController
  DAILY_MAX_PITCHES = 85
  CATCHER_LOCK_PITCHES = 71

  def create
    game = Game.find(params[:game_id])
    player = game.team.players.find(params[:player_id])

    pa = PitchAppearance.find_or_create_by!(
      game_id: game.id,
      player_id: player.id,
      pitched_on: pitched_on_for(game)
    )

    pa.update!(pitches_thrown: pa.pitches_thrown.to_i)

    redirect_to game_path(game)
  end

  def update
    @game = Game.find(params[:game_id])
    @player = @game.team.players.find(params[:id])

    pa = PitchAppearance.find_or_create_by!(
      game_id: @game.id,
      player_id: @player.id,
      pitched_on: pitched_on_for(@game)
    )

    if removed_from_mound?(pa)
      return render_pitch_error("#{@player.name} cannot pitch again after being removed.")
    end

    requested_val =
      if params[:pitches].present?
        [params[:pitches].to_i, 0].max
      else
        delta = params[:delta].to_i
        [pa.pitches_thrown.to_i + delta, 0].max
      end

    if requested_val != pa.pitches_thrown.to_i
      ok, msg = validate_day_rules!(
        player: @player,
        game: @game,
        pa: pa,
        new_game_pitches: requested_val
      )
      return render_pitch_error(msg) unless ok
    end

    pa.update!(pitches_thrown: requested_val)

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

  def remove
    game = Game.find(params[:game_id])
    player = game.team.players.find(params[:player_id])

    pa = PitchAppearance.find_or_create_by!(
      game_id: game.id,
      player_id: player.id,
      pitched_on: pitched_on_for(game)
    )

    pa.update!(removed_from_mound: true)

    respond_to do |format|
      format.html { redirect_to game_path(game) }
      format.turbo_stream { redirect_to game_path(game) }
    end
  end

  private

  def pitched_on_for(game)
    game.date
  end

  def removed_from_mound?(pa)
    pa.respond_to?(:removed_from_mound) && pa.removed_from_mound?
  end

  def validate_day_rules!(player:, game:, pa:, new_game_pitches:)
    date = pitched_on_for(game)

    other_today = player.pitch_appearances.with_pitches.where(pitched_on: date).where.not(id: pa.id).sum(:pitches_thrown).to_i
    new_day_total = other_today + new_game_pitches
    remaining = DAILY_MAX_PITCHES - other_today

    if new_day_total > DAILY_MAX_PITCHES
      return [false, "#{player.name} would exceed #{DAILY_MAX_PITCHES} pitches for #{date}. Remaining today: #{[remaining, 0].max}."]
    end

    day = player.player_days.find_by(date: date)
    caught_today = day&.caught_any? || false

    if caught_today && new_day_total >= CATCHER_LOCK_PITCHES
      allow_exception = ActiveModel::Type::Boolean.new.cast(params[:allow_finish_batter_exception])
      unless allow_exception
        return [false, "#{player.name} has already played catcher today and cannot reach #{CATCHER_LOCK_PITCHES}+ pitches today without an exception override."]
      end
    end

    [true, nil]
  end

  def render_pitch_error(message)
    respond_to do |format|
      format.html do
        redirect_to game_path(@game), alert: message
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "flash",
          partial: "shared/flash",
          locals: { alert: message }
        ), status: :unprocessable_entity
      end
      format.json do
        render json: { error: message }, status: :unprocessable_entity
      end
    end
  end
end
