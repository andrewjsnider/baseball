class Game < ApplicationRecord
  belongs_to :team
  has_one :lineup, dependent: :destroy

  after_create :build_default_lineup

  private

  def build_default_lineup
    create_lineup!
  end
end
