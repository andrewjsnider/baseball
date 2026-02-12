FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    age { rand(9..12) }

    # Rating card
    pitching_rating { rand(1..5) }
    hitting_rating { rand(1..5) }
    infield_defense_rating { rand(1..5) }
    outfield_defense_rating { rand(1..5) }
    catching_rating { rand(1..5) }
    baseball_iq { rand(1..5) }
    athleticism { rand(1..5) }
    speed { rand(1..5) }

    # Booleans
    can_pitch { false }
    can_catch { false }

    # Metadata
    tier { nil } # usually let computed_tier handle this
    confidence_level { rand(3..5) }
    manual_adjustment { 0 }
    evaluation_date { Date.today }
    risk_flag { false }

    notes { "Scouted player" }
    team { nil }

    # Legacy scoring still exists in model, so include safe defaults
    arm_strength { 0 }
    arm_accuracy { 0 }
    pitching_control { 0 }
    pitching_velocity { 0 }
    fielding { 0 }
    hitting_contact { 0 }
    hitting_power { 0 }
    coachability { 0 }
    parent_reliability { 0 }

    trait :pitcher do
      can_pitch { true }
      pitching_rating { 4 }
    end

    trait :catcher do
      can_catch { true }
      catching_rating { 4 }
    end

    trait :elite do
      pitching_rating { 5 }
      hitting_rating { 5 }
      infield_defense_rating { 5 }
      outfield_defense_rating { 5 }
      catching_rating { 5 }
      athleticism { 5 }
      baseball_iq { 5 }
      confidence_level { 5 }
    end
  end
end
