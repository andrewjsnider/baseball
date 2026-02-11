require "faker"

puts "Clearing data..."

PlayerPosition.destroy_all
Player.destroy_all
Position.destroy_all

puts "Creating positions..."

positions = %w[P C SS 2B 3B 1B OF]

positions.each do |pos|
  Position.create!(name: pos)
end

puts "Creating teams..."

Team::NAMES.each do |name|
  Team.find_or_create_by! name: name
end

puts "Created #{Team.count} teams."

puts "Creating players..."

100.times do
  player = Player.create!(
    name: Faker::Name.name,
    age: rand(11..12),
    arm_strength: rand(1..5),
    arm_accuracy: rand(1..5),
    pitching_control: rand(1..5),
    pitching_velocity: rand(1..5),
    catcher_skill: rand(1..5),
    speed: rand(1..5),
    fielding: rand(1..5),
    hitting_contact: rand(1..5),
    hitting_power: rand(1..5),
    baseball_iq: rand(1..5),
    coachability: rand(1..5),
    parent_reliability: rand(1..5),
    risk_flag: [true, false, false].sample,
    team_id: nil
  )

  # Assign 1–3 positions
  possible_positions = Position.all.sample(rand(1..3))

  possible_positions.each do |position|
    PlayerPosition.create!(player: player, position: position)
  end
end

puts "Created #{Player.count} players."
