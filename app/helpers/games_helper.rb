module GamesHelper
  def home_away(game)
    if game.home?
      'Home'
    elsif game.away?
      'Away'
    else
      'TBD'
    end
  end
end
