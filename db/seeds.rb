# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require "faker"

puts "Clearing players..."
Player.destroy_all

positions = %w[P C SS 2B 3B OF 1B]

100.times do
  Player.create!(
    name: Faker::Name.name,
    age: rand(11..12),
    primary_position: positions.sample,
    secondary_positions: positions.sample,
    throws: %w[R L].sample,
    bats: %w[R L S].sample,
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
    drafted: false
  )
end

puts "Created #{Player.count} players."
