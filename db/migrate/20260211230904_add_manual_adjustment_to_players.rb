class AddManualAdjustmentToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :manual_adjustment, :integer
  end
end
