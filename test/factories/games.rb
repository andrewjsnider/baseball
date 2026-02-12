FactoryBot.define do
  factory :game do
    team { nil }
    opponent { "MyString" }
    date { "2026-02-11" }
    location { "MyString" }
    notes { "MyText" }
    status { "MyString" }
  end
end
