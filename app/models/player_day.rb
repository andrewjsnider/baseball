class PlayerDay < ApplicationRecord
  belongs_to :player

  validates :date, presence: true
end
