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

  def print_plan
    @game = Game.find(params[:id])
    @presenter = GameShowPresenter.new(game: @game)
    render layout: "print"
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

    ids.each do |slot_id|
      slot = slots_by_id[slot_id]
      next unless slot

      attrs = slot_params[slot_id] || slot_params[slot_id.to_sym] || {}

      if slot.starter?
        slot.target_pitches = attrs[:target_pitches].presence || attrs["target_pitches"].presence
      else
        slot.player_id = attrs[:player_id].presence || attrs["player_id"].presence
        slot.target_pitches = attrs[:target_pitches].presence || attrs["target_pitches"].presence
      end

      slot.save!
    end

    redirect_to game_path(@game), notice: "Pitching plan updated."
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
