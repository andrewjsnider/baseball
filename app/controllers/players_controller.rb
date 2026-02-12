class PlayersController < ApplicationController
  before_action :set_player, only: %i[ show edit update destroy ]

  def index
    @players = Player.all
  end

  def show
  end

  def draft
    player = Player.find(params[:id])
    team = Team.find(params[:team_id])
    player.update!(team: team)
    redirect_back fallback_location: players_path
  end

  def undraft
    @player = Player.find(params[:id])
    @player.update(team_id: nil)

    redirect_back fallback_location: players_path
  end

  def assign
    @player = Player.find(params[:id])
    @teams = Team.all
  end

  def assign_to_team
    @player = Player.find(params[:id])
    team = Team.find_by(id: params[:team_id])

    if team
      @player.update!(team: team)
      redirect_to root_path
    else
      render :assign, status: :unprocessable_entity
    end
  end

  def new
    @player = Player.new
  end

  def edit
  end

  def create
    @player = Player.new(player_params)

    respond_to do |format|
      if @player.save
        format.html { redirect_to @player, notice: "Player was successfully created." }
        format.json { render :show, status: :created, location: @player }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  def import
    Player.import(params[:file])
    redirect_to players_path, notice: "Players imported."
  end

  def update
    respond_to do |format|
      if @player.update(player_params)
        format.html { redirect_to @player, notice: "Player was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @player }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @player.destroy!

    respond_to do |format|
      format.html { redirect_to players_path, notice: "Player was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_player
    @player = Player.find(params.expect(:id))
  end


  def player_params
    params.require(:player).permit(
      :name,
      :age,
      :tier,
      :confidence_level,
      :manual_adjustment,
      :notes,
      :risk_flag,
      :evaluation_date,
      :team_id,

      :pitching_rating,
      :hitting_rating,
      :infield_defense_rating,
      :outfield_defense_rating,
      :catching_rating,
      :baseball_iq,
      :athleticism,
      :speed,

      :can_pitch,
      :can_catch,

      position_ids: []
    )
  end
end
