class ChangePcrScoresToDecimals < ActiveRecord::Migration[8.0]
  def change
    change_column :players, :pcr_hitting,  :decimal, precision: 3, scale: 1
    change_column :players, :pcr_fielding, :decimal, precision: 3, scale: 1
    change_column :players, :pcr_throwing, :decimal, precision: 3, scale: 1
    change_column :players, :pcr_pitching, :decimal, precision: 3, scale: 1
    change_column :players, :pcr_total,    :decimal, precision: 4, scale: 1
  end
end
