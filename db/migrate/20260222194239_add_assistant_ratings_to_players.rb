class AddAssistantRatingsToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :assistant_pitching_rating, :integer
    add_column :players, :assistant_hitting_rating, :integer
    add_column :players, :assistant_infield_defense_rating, :integer
    add_column :players, :assistant_outfield_defense_rating, :integer
    add_column :players, :assistant_notes, :text
  end
end
