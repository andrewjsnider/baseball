class AddRatingsToPlayers < ActiveRecord::Migration[8.0]
   def change
    rename_column :players, :confidence, :confidence_level
    rename_column :players, :catcher_skill, :catching_rating
    add_column :players, :pitching_rating, :integer
    add_column :players, :hitting_rating, :integer
    add_column :players, :infield_defense_rating, :integer
    add_column :players, :outfield_defense_rating, :integer
    add_column :players, :athleticism, :integer
    add_column :players, :can_pitch, :boolean, default: false, null: false
    add_column :players, :can_catch, :boolean, default: false, null: false
  end
end
