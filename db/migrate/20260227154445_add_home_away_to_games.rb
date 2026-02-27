class AddHomeAwayToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :home_away, :string, null: false, default: "home"
    add_index :games, :home_away
  end
end
