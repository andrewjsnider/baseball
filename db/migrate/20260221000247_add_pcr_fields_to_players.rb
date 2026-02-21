class AddPcrFieldsToPlayers < ActiveRecord::Migration[8.0]
def change
    add_column :players, :pcr_id, :string
    add_column :players, :first_name, :string
    add_column :players, :last_name, :string

    add_column :players, :pcr_hitting, :integer
    add_column :players, :pcr_fielding, :integer
    add_column :players, :pcr_throwing, :integer
    add_column :players, :pcr_pitching, :integer
    add_column :players, :pcr_total, :integer

    add_column :players, :draftable, :boolean, default: true, null: false

    add_index :players, :pcr_id, unique: true
  end
end
