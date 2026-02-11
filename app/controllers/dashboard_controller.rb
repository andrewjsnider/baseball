class DashboardController < ApplicationController
  def index
    @total_players = Player.count
    @drafted_players = Player.where(drafted: true).count
    @undrafted_players = Player.where(drafted: false).count

    @top_pitchers = Player.where(drafted: false)
                          .sort_by(&:pitcher_score)
                          .reverse
                          .first(5)

    @top_overall = Player.where(drafted: false)
                         .sort_by(&:overall_score)
                         .reverse
                         .first(5)

    @risk_players = Player.where(risk_flag: true, drafted: false)
  end
end
