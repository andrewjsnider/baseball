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
    player.update!(team: team, drafted: true)
    redirect_back fallback_location: players_path
  end

  def undraft
    @player = Player.find(params[:id])
    @player.update!(team_id: nil, drafted: false, draft_round: nil)
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
    file = params[:file]
    raise ActionController::BadRequest, "Missing file" unless file.present?

    Rails.logger.info("========== IMPORT START #{file.original_filename} #{file.path}")

    result = PcrPlayersImporter.new(path: file.path).import!

    Rails.logger.info("========== IMPORT DONE #{result.inspect}")

    redirect_to players_path,
                notice: "Imported: #{result[:created]} created, #{result[:updated]} updated, #{result[:skipped]} skipped."
  rescue => e
    Rails.logger.error("========== IMPORT FAILED #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.first(20).join("\n"))

    redirect_to import_players_path, alert: "Import failed: #{e.class}: #{e.message}"
  end

  def evals
    q = params[:q].to_s.strip

    @players =
      if q.present?
        Player.where("name ILIKE ? OR pcr_id ILIKE ?", "%#{q}%", "%#{q}%")
      else
        Player.order(:last_name, :first_name, :name)
      end

    @player = params[:player_id].present? ? Player.find(params[:player_id]) : @players.first
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
    @player = Player.find(params[:id])
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
      :club_team,

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

      :pcr_id,
      :first_name,
      :last_name,
      :pcr_hitting,
      :pcr_fielding,
      :pcr_throwing,
      :pcr_pitching,
      :pcr_total,
      :draftable,

      position_ids: []
    )
  end
end
