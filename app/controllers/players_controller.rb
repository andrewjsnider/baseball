class PlayersController < ApplicationController
  before_action :set_player, only: %i[ show edit update destroy ]

  def index
    @players = Player.all
  end

  def show
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
      :primary_position,
      :secondary_positions,
      :arm_strength,
      :arm_accuracy,
      :pitching_control,
      :pitching_velocity,
      :catcher_skill,
      :speed,
      :fielding,
      :hitting_contact,
      :hitting_power,
      :baseball_iq,
      :coachability,
      :parent_reliability,
      :notes,
      :risk_flag
    )
  end
end
