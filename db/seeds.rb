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

positions = Position.all.index_by(&:name)

100.times do
  # Bias distribution toward average players
  base = rand(1..5)

  player = Player.create!(
    name: Faker::Name.name,
    age: rand(11..12),
    arm_strength: rand(base..5),
    arm_accuracy: rand(1..5),
    pitching_control: rand(1..5),
    pitching_velocity: rand(1..5),
    catcher_skill: rand(1..5),
    speed: rand(1..5),
    fielding: rand(1..5),
    hitting_contact: rand(1..5),
    hitting_power: rand(1..5),
    baseball_iq: rand(2..5),
    coachability: rand(2..5),
    parent_reliability: rand(2..5),
    risk_flag: rand < 0.2,
    confidence: rand(2..5),
    evaluation_date: rand < 0.2 ? 2.years.ago : Date.today,
    team_id: nil
  )

  assigned_positions = []

  # ~40% can pitch
  if rand < 0.4
    assigned_positions << positions["P"]
    # Real pitchers should have higher control
    player.update!(
      pitching_control: rand(3..5),
      pitching_velocity: rand(2..5)
    )
  end

  # ~20% catchers
  assigned_positions << positions["C"] if rand < 0.2

  # Always at least one field position
  field_positions = %w[SS 2B 3B 1B OF]
  assigned_positions << positions[field_positions.sample]

  # 30% multi-position
  if rand < 0.3
    assigned_positions << positions[field_positions.sample]
  end

  assigned_positions.compact.uniq.each do |position|
    PlayerPosition.create!(player: player, position: position)
  end
end

puts "Created #{Player.count} players."
