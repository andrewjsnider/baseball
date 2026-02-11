# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_11_230904) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "player_positions", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "position_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_player_positions_on_player_id"
    t.index ["position_id"], name: "index_player_positions_on_position_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.string "age"
    t.string "height"
    t.string "primary_position"
    t.string "secondary_positions"
    t.string "throws"
    t.string "bats"
    t.integer "arm_strength"
    t.integer "arm_accuracy"
    t.integer "pitching_control"
    t.integer "pitching_velocity"
    t.integer "catcher_skill"
    t.integer "speed"
    t.integer "fielding"
    t.integer "hitting_contact"
    t.integer "hitting_power"
    t.integer "baseball_iq"
    t.integer "coachability"
    t.integer "parent_reliability"
    t.text "notes"
    t.boolean "risk_flag"
    t.boolean "drafted"
    t.integer "draft_round"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tier"
    t.bigint "team_id"
    t.date "evaluation_date"
    t.integer "confidence"
    t.integer "manual_adjustment"
    t.index ["team_id"], name: "index_players_on_team_id"
  end

  create_table "positions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "player_positions", "players"
  add_foreign_key "player_positions", "positions"
  add_foreign_key "players", "teams"
end
