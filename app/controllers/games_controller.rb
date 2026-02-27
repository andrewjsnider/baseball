class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy]

  def index
    @games = Game.order(date: :asc)
  end

  def show
    @game = Game.includes(lineup: { lineup_slots: :player }).find(params[:id])
    @opponent_team = @game.opponent_team
    @opponent_players =
    if @opponent_team
      @opponent_team.players.order(Arel.sql("COALESCE(pcr_total, 0) DESC"))
    else
      Player.none
    end

    @show = GameShowPresenter.new(game: @game, opponent_team: @opponent_team, opponent_players: @opponent_players)

    @opponent_top_hitters = @opponent_players.sort_by { |p| -(p.hitting_rating.to_i) }.first(5)
    @opponent_top_pitchers = @opponent_players.select(&:can_pitch).sort_by { |p| -(p.pitching_rating.to_i) }.first(3)
    @opponent_top_runners = @opponent_players.sort_by { |p| -(p.speed.to_i) }.first(5)
  end

  def pitch_plan
    @game = Game.find(params[:id])

    slot_params = params.fetch(:pitch_plan_slots, {})
    only_slot_id = params[:only_slot_id].presence

    ids =
      if only_slot_id
        [only_slot_id.to_s]
      else
        slot_params.keys
      end

    slots_by_id = @game.game_pitch_plan_slots.where(id: ids).index_by { |s| s.id.to_s }

    # Build the "final" player assignments after this update, so we can enforce
    # "a pitcher can only appear once" even when saving a single slot.
    final_player_ids_by_slot_id = {}

    @game.game_pitch_plan_slots.each do |slot|
      existing_player_id =
        if slot.starter? && @game.lineup&.lineup_slots&.pitcher&.first&.player_id.present?
          @game.lineup.lineup_slots.pitcher.first.player_id
        else
          slot.player_id
        end

      final_player_ids_by_slot_id[slot.id.to_s] = existing_player_id.presence&.to_i
    end

    ids.each do |slot_id|
      slot = slots_by_id[slot_id]
      next if slot.nil?

      # Starter is derived from lineup, do not allow overriding via params
      next if slot.starter? && @game.lineup&.lineup_slots&.pitcher&.first&.player_id.present?

      attrs = slot_params[slot_id] || {}
      incoming_player_id = attrs[:player_id].presence&.to_i

      final_player_ids_by_slot_id[slot_id] = incoming_player_id
    end

    assigned_player_ids = final_player_ids_by_slot_id.values.compact
    if assigned_player_ids.uniq.size != assigned_player_ids.size
      redirect_to game_path(@game), alert: "A pitcher can only be assigned to one role in the plan."
      return
    end

    ids.each do |slot_id|
      slot = slots_by_id[slot_id]
      next if slot.nil?

      # Starter is derived from lineup, do not allow overriding via params
      if slot.starter? && @game.lineup&.lineup_slots&.pitcher&.first&.player_id.present?
        next
      end

      attrs = slot_params[slot_id] || {}
      player_id = attrs[:player_id].presence
      target_pitches = attrs[:target_pitches].presence

      slot.update!(
        player_id: player_id,
        target_pitches: target_pitches
      )
    end

    redirect_to game_path(@game)
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    @game.opponent = Team.find_by(name: game_params[:opponent])
    @game.team = @my_team
    if @game.save
      redirect_to @game
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @game.update(game_params)
      redirect_to @game
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @game.destroy
    redirect_to games_path
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(
      :team_id,
      :opponent_team_id,
      :opponent,
      :date,
      :location,
      :notes,
      :status,
      :home_away,
    )
  end
end
