class GamePitchPlanSlotsController < ApplicationController
  def update
    game = Game.find(params[:game_id])
    slot = game.game_pitch_plan_slots.find(params[:id])

    slot.update!(
      player_id: params.dig(:game_pitch_plan_slot, :player_id).presence,
      target_pitches: params.dig(:game_pitch_plan_slot, :target_pitches).presence,
      notes: params.dig(:game_pitch_plan_slot, :notes).presence
    )

    redirect_to game_path(game)
  end
end