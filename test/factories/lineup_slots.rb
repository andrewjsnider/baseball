FactoryBot.define do
  factory :lineup_slot do
    lineup { nil }
    player { nil }
    batting_order { 1 }
    field_position { 1 }
  end
end
