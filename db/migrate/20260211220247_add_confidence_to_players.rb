class AddConfidenceToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :confidence, :integer
  end
end
