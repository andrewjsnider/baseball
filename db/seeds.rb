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
  age = rand < 0.6 ? 12 : 11   # 60% 12-year-olds

  # Slight physical bias for 12-year-olds
  arm_strength = age == 12 ? rand(2..5) : rand(1..4)
  pitching_velocity = age == 12 ? rand(2..5) : rand(1..4)
  speed = age == 12 ? rand(2..5) : rand(1..4)

  player = Player.create!(
    name: Faker::Name.name,
    age: age,

    # New rating card
    pitching_rating: rand(1..5),
    hitting_rating: rand(1..5),
    infield_defense_rating: rand(1..5),
    outfield_defense_rating: rand(1..5),
    catching_rating: rand(1..5),
    baseball_iq: rand(2..5),
    athleticism: rand(1..5),
    speed: speed,

    # Booleans
    can_pitch: rand < 0.5,
    can_catch: rand < 0.3,

    # Metadata
    tier: Player::TIERS.sample,
    risk_flag: rand < 0.2,
    confidence_level: rand(2..5),
    evaluation_date: rand < 0.2 ? 2.years.ago : Date.today,
    manual_adjustment: [nil, -5, 0, 5].sample,

    notes: Faker::Lorem.sentence,
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
