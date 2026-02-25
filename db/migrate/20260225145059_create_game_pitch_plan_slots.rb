class CreateGamePitchPlanSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :game_pitch_plan_slots do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: true, foreign_key: true

      t.integer :role, null: false
      t.integer :target_pitches

      t.text :notes
      t.timestamps
    end

    add_index :game_pitch_plan_slots, [:game_id, :role], unique: true
  end
end
