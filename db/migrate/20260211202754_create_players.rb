class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :name
      t.string :age
      t.string :height
      t.string :primary_position
      t.string :secondary_positions
      t.string :throws
      t.string :bats
      t.integer :arm_strength
      t.integer :arm_accuracy
      t.integer :pitching_control
      t.integer :pitching_velocity
      t.integer :catcher_skill
      t.integer :speed
      t.integer :fielding
      t.integer :hitting_contact
      t.integer :hitting_power
      t.integer :baseball_iq
      t.integer :coachability
      t.integer :parent_reliability
      t.text :notes
      t.boolean :risk_flag
      t.boolean :drafted
      t.integer :draft_round

      t.timestamps
    end
  end
end
