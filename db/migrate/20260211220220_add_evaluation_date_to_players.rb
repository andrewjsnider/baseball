class AddEvaluationDateToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :evaluation_date, :date
  end
end
