class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_team

  def set_team
    @team ||= Team.find_by(name: 'Giants')
  end
end
