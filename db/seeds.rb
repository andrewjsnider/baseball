# db/seeds.rb
require "faker"

puts "Clearing data..."

# If you have other tables (games, lineups, etc), add them here in the right order.
PlayerPosition.destroy_all
Player.destroy_all
Position.destroy_all
Team.destroy_all

puts "Creating positions..."

position_names = %w[P C SS 2B 3B 1B OF]
position_names.each { |pos| Position.create!(name: pos) }

positions_by_name = Position.all.index_by(&:name)

puts "Creating teams..."

# Create the league teams from your constant, then guarantee "Giants" exists
if defined?(Team::NAMES) && Team::NAMES.respond_to?(:each)
  Team::NAMES.each { |name| Team.find_or_create_by!(name: name) }
end

Team.find_or_create_by!(name: "Giants")

puts "Created #{Team.count} teams."

# puts "Creating players..."

# def biased_rating_1_to_5
#   # Bias toward 3 using a simple average of two uniform rolls
#   ((rand(1..5) + rand(1..5)) / 2.0).round.clamp(1, 5)
# end

# 100.times do
#   age_num = rand < 0.6 ? 12 : 11 # 60% 12-year-olds

#   # Slight physical bias for 12-year-olds
#   arm_strength      = age_num == 12 ? rand(2..5) : rand(1..4)
#   pitching_velocity = age_num == 12 ? rand(2..5) : rand(1..4)
#   speed             = age_num == 12 ? rand(2..5) : rand(1..4)

#   base = biased_rating_1_to_5

#   player = Player.create!(
#     name: Faker::Name.name,
#     age: age_num.to_s,

#     # Legacy-ish physicals (now actually used)
#     arm_strength: arm_strength,
#     pitching_velocity: pitching_velocity,
#     speed: speed,

#     # Rating card
#     pitching_rating: base,
#     hitting_rating: base,
#     infield_defense_rating: base,
#     outfield_defense_rating: base,
#     catching_rating: base,
#     baseball_iq: [base, rand(2..5)].sample,
#     athleticism: base,

#     # Booleans
#     can_pitch: false,
#     can_catch: false,
#     club_team: rand < 0.2,

#     # Metadata
#     tier: Player::TIERS.sample,
#     risk_flag: rand < 0.2,
#     confidence_level: rand(2..5),
#     evaluation_date: (rand < 0.2 ? 2.years.ago.to_date : Date.today),
#     manual_adjustment: [nil, -5, 0, 5].sample,

#     drafted: false,
#     draft_round: nil,
#     team_id: nil,

#     draftable: true,
#     notes: Faker::Lorem.sentence,

#     # PCR fields default empty (import fills these later)
#     pcr_id: nil,
#     first_name: nil,
#     last_name: nil,
#     pcr_hitting: nil,
#     pcr_fielding: nil,
#     pcr_throwing: nil,
#     pcr_pitching: nil,
#     pcr_total: nil
#   )

#   assigned_positions = []

#   # ~40% pitchers
#   if rand < 0.4
#     assigned_positions << positions_by_name["P"]
#     player.update!(
#       can_pitch: true,
#       pitching_control: rand(3..5),
#       pitching_velocity: [player.pitching_velocity.to_i, rand(2..5)].max,
#       pitching_rating: [player.pitching_rating.to_i, rand(3..5)].max
#     )
#   end

#   # ~20% catchers
#   if rand < 0.2
#     assigned_positions << positions_by_name["C"]
#     player.update!(
#       can_catch: true,
#       catching_rating: [player.catching_rating.to_i, rand(3..5)].max
#     )
#   end

#   # Always at least one field position
#   field_positions = %w[SS 2B 3B 1B OF]
#   assigned_positions << positions_by_name[field_positions.sample]

#   # 30% multi-position
#   assigned_positions << positions_by_name[field_positions.sample] if rand < 0.3

#   assigned_positions.compact.uniq.each do |position|
#     PlayerPosition.create!(player: player, position: position)
#   end
# end

# puts "Created #{Player.count} players."
puts "Done."