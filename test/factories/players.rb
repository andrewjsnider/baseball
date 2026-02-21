FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    age { rand(9..12).to_s } # your schema has age as string

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
    club_team { false }

    # Metadata
    tier { nil }
    confidence_level { rand(3..5) }
    manual_adjustment { 0 }
    evaluation_date { Date.today }
    risk_flag { false }
    draftable { true }

    notes { "Scouted player" }
    team { nil }

    # Legacy fields: leave nil so they don't trip 1..5 validations
    arm_strength { nil }
    arm_accuracy { nil }
    pitching_control { nil }
    pitching_velocity { nil }
    fielding { nil }
    hitting_contact { nil }
    hitting_power { nil }
    coachability { nil }
    parent_reliability { nil }

    # PCR import fields (optional)
    pcr_id { nil }
    first_name { nil }
    last_name { nil }
    pcr_hitting { nil }
    pcr_fielding { nil }
    pcr_throwing { nil }
    pcr_pitching { nil }
    pcr_total { nil }

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

    trait :pcr_only do
      pcr_id { "PCR#{rand(1000..9999)}" }
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
      name { "#{first_name} #{last_name}" }

      pcr_hitting { rand(1..5) }
      pcr_fielding { rand(1..5) }
      pcr_throwing { rand(1..5) }
      pcr_pitching { rand(1..5) }
      pcr_total { pcr_hitting + pcr_fielding + pcr_throwing + pcr_pitching }

      # Make rating card blank so you test PCR scoring path
      pitching_rating { nil }
      hitting_rating { nil }
      infield_defense_rating { nil }
      outfield_defense_rating { nil }
      catching_rating { nil }
      athleticism { nil }
      baseball_iq { nil }
      speed { nil }
      confidence_level { nil }
    end
  end
end