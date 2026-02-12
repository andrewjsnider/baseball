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

ActiveRecord::Schema[8.0].define(version: 2026_02_12_013025) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "games", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.string "opponent"
    t.date "date"
    t.string "location"
    t.text "notes"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_games_on_team_id"
  end

  create_table "lineup_slots", force: :cascade do |t|
    t.bigint "lineup_id", null: false
    t.bigint "player_id", null: false
    t.integer "batting_order"
    t.integer "field_position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lineup_id"], name: "index_lineup_slots_on_lineup_id"
    t.index ["player_id"], name: "index_lineup_slots_on_player_id"
  end

  create_table "lineup_spots", force: :cascade do |t|
    t.bigint "lineup_id", null: false
    t.bigint "player_id", null: false
    t.integer "batting_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lineup_id"], name: "index_lineup_spots_on_lineup_id"
    t.index ["player_id"], name: "index_lineup_spots_on_player_id"
  end

  create_table "lineups", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "starting_pitcher_id"
    t.integer "planned_pitch_limit"
    t.index ["game_id"], name: "index_lineups_on_game_id"
  end

  create_table "pitch_appearances", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "game_id", null: false
    t.integer "pitches_thrown"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_pitch_appearances_on_game_id"
    t.index ["player_id"], name: "index_pitch_appearances_on_player_id"
  end

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
    t.integer "catching_rating"
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
    t.integer "confidence_level"
    t.integer "manual_adjustment"
    t.integer "pitching_rating"
    t.integer "hitting_rating"
    t.integer "infield_defense_rating"
    t.integer "outfield_defense_rating"
    t.integer "athleticism"
    t.boolean "can_pitch", default: false, null: false
    t.boolean "can_catch", default: false, null: false
    t.boolean "club_team"
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

  add_foreign_key "games", "teams"
  add_foreign_key "lineup_slots", "lineups"
  add_foreign_key "lineup_slots", "players"
  add_foreign_key "lineup_spots", "lineups"
  add_foreign_key "lineup_spots", "players"
  add_foreign_key "lineups", "games"
  add_foreign_key "pitch_appearances", "games"
  add_foreign_key "pitch_appearances", "players"
  add_foreign_key "player_positions", "players"
  add_foreign_key "player_positions", "positions"
  add_foreign_key "players", "teams"
end
