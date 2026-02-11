class AddTierToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :tier, :string
  end
end
