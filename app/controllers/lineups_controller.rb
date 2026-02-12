class LineupsController < ApplicationController
  before_action :set_game
  before_action :set_lineup

  def show
  end

  def reorder
    LineupSlot.transaction do
      params[:player_ids].each_with_index do |id, index|
        slot = @lineup.lineup_slots.find_by!(player_id: id)
        slot.update!(batting_order: index + 1)
      end
    end

    head :ok
  end

  def create
    @lineup = @game.create_lineup

    @team.players.each_with_index do |player, index|
      @lineup.lineup_slots.create!(
        player: player,
        batting_order: index + 1
      )
    end

    redirect_to game_lineup_path(@game)
  end

  def update_pitch_limit
    @lineup.update!(planned_pitch_limit: params[:planned_pitch_limit])
    head :ok
  end

  def assign_positions
    params[:positions].each do |player_id, position|
      LineupSlot.transaction do
        slot = @lineup.lineup_slots.find_by!(player_id: player_id)

        if position.present?
          existing = @lineup.lineup_slots.find_by(field_position: position)
          existing&.update!(field_position: nil)
          slot.update!(field_position: position)
        else
          slot.update!(field_position: nil)
        end
      end
    end

    head :ok
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def set_lineup
    @lineup = @game.lineup

    unless @lineup
      @lineup = @game.create_lineup

      @game.team.players.each_with_index do |player, index|
        @lineup.lineup_slots.create!(
          player: player,
          batting_order: index + 1,
          field_position: :extra_hitter,
        )
      end
    end
  end
end
