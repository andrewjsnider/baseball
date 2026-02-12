class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.references :team, null: false, foreign_key: true
      t.string :opponent
      t.date :date
      t.string :location
      t.text :notes
      t.string :status

      t.timestamps
    end
  end
end
