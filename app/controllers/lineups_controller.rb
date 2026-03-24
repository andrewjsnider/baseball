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

    @my_team.players.each_with_index do |player, index|
      @lineup.lineup_slots.create!(
        player: player,
        batting_order: index + 1,
        field_position: :extra_hitter,
        field_position_first_two: :extra_hitter,
        field_position_second_two: :extra_hitter
      )
    end

    redirect_to game_lineup_path(@game)
  end

  def update_pitch_limit
    @lineup.update!(planned_pitch_limit: params[:planned_pitch_limit])
    head :ok
  end

  def assign_positions
    field_name = params[:field_name].to_s

    unless allowed_position_fields.include?(field_name)
      render json: { errors: ["Invalid position field."] }, status: :unprocessable_entity
      return
    end

    errors = []

    LineupSlot.transaction do
      params[:positions].each do |player_id, position|
        slot = @lineup.lineup_slots.find_by!(player_id: player_id)
        requested = normalized_position_value(position)
        player = slot.player

        if requested == "catcher"
          if player.pitches_thrown_on_date(@game.date) >= 71
            errors << "#{player.name} cannot play catcher after throwing 71+ pitches today."
            next
          end

          day = player.player_day_for(@game.date)
          day.update!(caught_any: true) unless day.caught_any?
        end

        if requested.present?
          existing = @lineup.lineup_slots.find_by(field_name => requested)

          if existing && existing != slot && requested != "extra_hitter"
            errors << "#{requested.humanize} is already assigned for this inning block."
            next
          end

          slot.update!(field_name => requested)
        else
          slot.update!(field_name => :extra_hitter)
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { errors: errors }, status: :unprocessable_entity
      return
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
          field_position_first_two: :extra_hitter,
          field_position_second_two: :extra_hitter
        )
      end
    end
  end

  def allowed_position_fields
    %w[field_position_first_two field_position_second_two]
  end

  def normalized_position_value(position)
    value = position.to_s.strip
    return "extra_hitter" if value.blank?
    value
  end
end
