class InSeasonDashboardController < ApplicationController
  def index
    today = Date.current
    @team = Team.first

    @next_game = Game.where("date >= ?", today).order(:date).first
    @upcoming_games = Game.where("date >= ?", today).order(:date).limit(5)
    @recent_games = Game.where("date < ?", today).order(date: :desc).limit(5)

    @presenter =
      InSeasonDashboardPresenter.new(
        team: @team,
        today: today,
        next_game: @next_game,
        upcoming_games: @upcoming_games,
        recent_games: @recent_games
      )
  end
end