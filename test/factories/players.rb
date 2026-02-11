FactoryBot.define do
  factory :player do
    name { "MyString" }
    age { "MyString" }
    height { "MyString" }
    primary_position { "MyString" }
    secondary_positions { "MyString" }
    throws { "MyString" }
    bats { "MyString" }
    arm_strength { 1 }
    arm_accuracy { 1 }
    pitching_control { 1 }
    pitching_velocity { 1 }
    catcher_skill { 1 }
    speed { 1 }
    fielding { 1 }
    hitting_contact { 1 }
    hitting_power { 1 }
    baseball_iq { 1 }
    coachability { 1 }
    parent_reliability { 1 }
    notes { "MyText" }
    risk_flag { false }
    drafted { false }
    draft_round { 1 }
  end
end
