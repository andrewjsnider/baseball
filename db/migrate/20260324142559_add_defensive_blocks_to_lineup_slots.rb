class AddDefensiveBlocksToLineupSlots < ActiveRecord::Migration[8.0]
  def change
    add_column :lineup_slots, :field_position_first_two, :integer
    add_column :lineup_slots, :field_position_second_two, :integer
  end
end
