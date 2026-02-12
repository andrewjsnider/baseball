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

  def assign_positions
    params[:positions].each do |player_id, position|
      slot = @lineup.lineup_slots.find_by!(player_id: player_id)
      slot.update!(field_position: position)
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
          field_position: :bench
        )
      end
    end
  end
end
