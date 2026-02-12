class CreatePitchAppearances < ActiveRecord::Migration[8.0]
  def change
    create_table :pitch_appearances do |t|
      t.references :player, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :pitches_thrown

      t.timestamps
    end
  end
end
