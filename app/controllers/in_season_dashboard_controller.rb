class InSeasonDashboardController < ApplicationController
  def index
    today = Date.current

    @next_game = Game.where("date >= ?", today).order(:date).first
    @upcoming_games = Game.where("date >= ?", today).order(:date).limit(5)
    @recent_games = Game.where("date < ?", today).order(date: :desc).limit(5)

    @roster = Player.where(team: Team.first)
    @pitchers = @roster.select(&:can_pitch?)
  end
end
